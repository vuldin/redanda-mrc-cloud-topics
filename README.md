# Multi-Region Redpanda Cloud Topics Demo (AWS)

A single Redpanda cluster stretched across 3 AWS regions using **Cloud Topics** (beta, v25.3+). Cloud Topics use S3 as the primary durable store instead of cross-region Raft replication, eliminating 90%+ of inter-region network replication costs.

## Architecture

```
┌──────────────────────────┐  VPC Peering ┌──────────────────────────┐
│   us-east-1              │◄────────────►│   eu-west-1              │
│   VPC 10.0.0.0/16        │              │   VPC 10.1.0.0/16        │
│                          │              │                          │
│  broker-0, broker-1      │              │  broker-2, broker-3      │
│       ↓ (SigV4)          │              │       ↓ (SigV4)          │
│  envoy-proxy:9000        │              │  envoy-proxy:9000        │
│       ↓ (SigV4A)         │              │       ↓ (SigV4A)         │
│  S3 bucket (US) ◄──CRR───────────────────── S3 bucket (EU)         │
│  workload-gen            │              │  workload-gen            │
│  prometheus + grafana    │              │                          │
└────────┬─────────────────┘              └────────┬─────────────────┘
         │           VPC Peering                   │
         │    ┌──────────────────────────┐         │
         └───►│   ap-southeast-1         │◄────────┘
              │   VPC 10.2.0.0/16        │
              │  broker-4, broker-5      │
              │  envoy-proxy:9000        │
              │  S3 bucket (AP)          │
              │  workload-gen            │
              └──────────────────────────┘

All 3 S3 buckets connected via MRAP + bi-directional CRR
```

## Key Innovation: Envoy SigV4→SigV4A Proxy

Redpanda's S3 client only supports SigV4 signing, but S3 Multi-Region Access Points (MRAP) require SigV4A (ECDSA-P256). Envoy proxy runs in each region as a transparent signing translator:

1. Redpanda sends SigV4-signed requests to local Envoy (port 9000)
2. Envoy strips existing auth, re-signs with SigV4A using IAM instance credentials
3. Envoy forwards to MRAP endpoint over TLS
4. MRAP routes to nearest regional S3 bucket

## Prerequisites

- **AWS CLI v2** configured with SSO or IAM credentials with admin-level permissions
  - SSO example: `aws sso login --profile sandbox-cse && export AWS_PROFILE=sandbox-cse`
- **Terraform >= 1.5.0**
- **Ansible >= 2.14** (installed via pipx or pip)
  - `jmespath` must be installed in the same Python environment as Ansible (e.g. `pipx inject ansible jmespath`)
- **Redpanda enterprise license** (Cloud Topics requires it)
  - Place the license key in `redpanda.license` or set `REDPANDA_LICENSE` env var
- **SSH key pair** — set `TF_VAR_ssh_public_key_path` to your public key path

## Quick Start

```bash
# Set your license
export REDPANDA_LICENSE="$(cat redpanda.license)"

# Set SSH key (if not using default ~/.ssh/id_rsa.pub)
export TF_VAR_ssh_public_key_path="~/.ssh/mrc-demo.pub"

# Deploy everything
./scripts/deploy.sh

# Tear down when done
./scripts/teardown.sh
```

## Manual Deployment

Recommended to run playbooks one at a time to catch issues early.

```bash
# 1. Terraform
cd terraform
terraform init
terraform apply

# 2. Ansible setup
export ANSIBLE_COLLECTIONS_PATH=${PWD}/../artifacts/collections
export ANSIBLE_ROLES_PATH=${PWD}/../artifacts/roles
export ANSIBLE_INVENTORY=${PWD}/../artifacts/hosts_mrc.ini
export ANSIBLE_HOST_KEY_CHECKING=False

cd ../ansible
ansible-galaxy collection install -r requirements.yml --force -p $ANSIBLE_COLLECTIONS_PATH
ansible-galaxy role install -r requirements.yml --force -p $ANSIBLE_ROLES_PATH

# 3. Deploy components (run one at a time)
ansible-playbook deploy-envoy.yml
ansible-playbook provision-cluster.yml
ansible-playbook configure-cloud-topics.yml
ansible-playbook deploy-monitor.yml
ansible-playbook deploy-workload.yml
```

## Demo Topics

Two cloud topics are created to demonstrate different leader placement strategies:

- **`demo-cloud-topic`** — leaders pinned to `us-east-1` via
  `redpanda.leaders.preference=racks:us-east-1`. Demonstrates primary-region ingest
  with low-latency local writes and cross-region reads via follower fetching from S3.
- **`demo-global-topic`** — no leader preference, leaders balanced across all 3
  regions. Demonstrates true multi-region writes where any region can produce equally.

## Known Issues

- **Redpanda startup timeout**: Cross-region cluster formation can exceed the
  default systemd start timeout. The Ansible `provision-cluster.yml` playbook may
  report failures, but brokers will finish joining the cluster shortly after. Verify
  with `rpk cluster health` on any broker before proceeding.
- **Redpanda version format**: The `redpanda_version` variable must use the full
  package version (e.g. `25.3.9-1`), not just the minor version (`25.3`).
  Check available versions: `apt-cache madison redpanda` on any broker.
- **configure-cloud-topics hang**: The `rpk cluster config set` commands may hang
  on the first broker after enabling cloud topics. The config changes still apply
  cluster-wide. If the playbook hangs, cancel it, verify config from another broker
  (`rpk cluster config get <key>`), and run the topic creation commands manually.
- **Teardown requires SSH key path**: `terraform destroy` needs
  `TF_VAR_ssh_public_key_path` set to the same key used during `apply`.

## Customization

Key variables in `terraform/variables.tf`:

| Variable | Default | Description |
|----------|---------|-------------|
| `deployment_prefix` | `mrc` | Resource name prefix |
| `broker_instance_type` | `i3.large` | Broker EC2 type (NVMe SSD) |
| `brokers_per_region` | `2` | Brokers per region |
| `redpanda_version` | `25.3.9-1` | Redpanda version (full package version) |
| `ssh_public_key_path` | `~/.ssh/id_rsa.pub` | Path to SSH public key |

## Verification

```bash
# Cluster health
ssh <broker> 'rpk cluster health'

# Cloud topic status
ssh <broker> 'rpk topic describe demo-cloud-topic'

# Envoy proxy stats
ssh <broker> 'curl -s http://localhost:9901/stats | grep s3_mrap'

# S3 bucket contents
aws s3 ls s3://mrc-cloud-topics-us-east-1/ --recursive | head
```

## Estimated Cost

~$35-60/day. Tear down when not in use.

## Files

```
terraform/          # AWS infrastructure (VPCs, peering, S3/MRAP, EC2, IAM)
ansible/            # Cluster provisioning, Envoy, monitoring, workload
dashboards/         # Grafana dashboards (cross-region + S3 traffic)
scripts/            # deploy.sh, teardown.sh
```

