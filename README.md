# Multi-Region Cloud Topics Demo (GCP)

Deploys a single Redpanda stretch cluster across three GCP regions with **Cloud Topics** backed by a GCS multi-region bucket. This validates a multi-region stretch cluster architecture with cloud-backed storage across US, EU, and Asia.

## Architecture

```
Single Redpanda Cluster (6 brokers: 2 per region)
├── us-east4 (N. Virginia):   2 brokers, rack=us-east4
├── europe-west1 (Belgium):   2 brokers, rack=europe-west1
├── asia-northeast3 (Seoul):  2 brokers, rack=asia-northeast3
├── GCS bucket (US multi-region): all brokers read/write directly over TLS
├── Monitoring: Prometheus + Grafana in us-east4
└── Clients: 1 producer/consumer per region
```

**Key simplification over the AWS version:** No Envoy proxy. GCS uses native credentials (GCE service account metadata), so Redpanda connects directly to `storage.googleapis.com:443`. The AWS version required an Envoy SigV4→SigV4A proxy for S3 MRAP — that entire layer is eliminated here.

## Cloud Topics: How It Works

With Cloud Topics, **data is not acknowledged to producers until uploaded to cloud storage (GCS)**. This means:

- **GCS is the durability guarantee**, not raft replication between brokers
- **RF=1 is the recommended replication factor** — durability comes from GCS, not replicas
- Produce latency is bounded by the GCS upload time from each region
- No cross-region raft replication overhead

### RF=1 and Partition Placement

With RF=1, `redpanda.leaders.preference` (leader pinning) has **no effect** because there is only one replica per partition — it IS the leader. The partition balancer also does not move RF=1 partitions to preferred racks.

To ensure partitions are on the correct regional brokers, use [`rpk cluster partitions move`](https://docs.redpanda.com/current/reference/rpk/rpk-cluster/rpk-cluster-partitions-move/) after topic creation:

```bash
# Create topic
rpk topic create ct-us -c redpanda.storage.mode=cloud -p 2 -r 1

# Move partitions to US brokers (0 and 1)
rpk cluster partitions move ct-us -p 0:0
rpk cluster partitions move ct-us -p 1:1
```

This is the optimal pattern: **per-region topics with RF=1 and locally-placed partitions**. Producers write to their local broker, which uploads to GCS. GCS provides cross-region durability.

### Measured Produce Latency

All latencies measured with RF=1, local broker, cloud topics uploading to a US multi-region GCS bucket:

| Region | Avg Produce Latency | GCS Distance |
|--------|-------------------|--------------|
| **US (us-east4)** | 280–445 ms | Local (US multi-region) |
| **EU (europe-west1)** | 300–714 ms | ~100ms to GCS |
| **Korea (asia-northeast3)** | 580–986 ms | ~200ms to GCS |

These are within the expected cloud topics range (250ms–1s) documented by Redpanda.

## Prerequisites

- **Terraform** >= 1.5.0
- **Ansible** >= 2.14 with `ansible-galaxy`
- **gcloud CLI** authenticated (`gcloud auth application-default login`)
- **GCP project** with billing enabled and Compute Engine API activated
- **SSH key pair** (default: `~/.ssh/id_rsa.pub`)
- **Redpanda v26.1+** enterprise license (Cloud Topics GA in v26.1)
- **Python jmespath** (`pip3 install jmespath`)

## Quick Start

```bash
# Set required environment variables
export TF_VAR_gcp_project="your-gcp-project-id"
export TF_VAR_ssh_public_key_path="~/.ssh/id_rsa.pub"
export REDPANDA_LICENSE="your-license-key"

# Deploy everything
./scripts/deploy.sh

# Tear down
./scripts/teardown.sh
```

## What Gets Deployed

| Resource | Count | Region(s) | Purpose |
|----------|-------|-----------|---------|
| VPC networks | 3 | us-east4, europe-west1, asia-northeast3 | Network isolation per region |
| VPC peering | 3 pairs | Cross-region | Full mesh connectivity |
| GCS bucket | 1 | US (multi-region) | Cloud Topics storage |
| Broker instances | 6 (2/region) | All three | Redpanda brokers (n2-standard-4 + local NVMe SSD) |
| Client instances | 3 (1/region) | All three | Workload generators (e2-medium) |
| Monitor instance | 1 | us-east4 | Prometheus + Grafana (e2-medium) |
| Service account | 1 | Project-level | GCS access for brokers |

## Demo Topics

The recommended pattern is per-region topics with RF=1, partitions manually placed on regional brokers:

| Topic | Partitions | RF | Brokers | Purpose |
|-------|-----------|-----|---------|---------|
| `ct-us` | 2 | 1 | 0, 1 (US) | US producers write here |
| `ct-eu` | 2 | 1 | 2, 3 (EU) | EU producers write here |
| `ct-kr` | 2 | 1 | 4, 5 (Korea) | Korea producers write here |

After topic creation, place partitions with:

```bash
rpk cluster partitions move ct-us -p 0:0 -p 1:1
rpk cluster partitions move ct-eu -p 0:2 -p 1:3
rpk cluster partitions move ct-kr -p 0:4 -p 1:5
```

## Configuration

### Cluster Properties

```bash
# Enable cloud storage with GCS
rpk cluster config set cloud_storage_enabled true
rpk cluster config set cloud_storage_credentials_source gcp_instance_metadata
rpk cluster config set cloud_storage_api_endpoint storage.googleapis.com
rpk cluster config set cloud_storage_api_endpoint_port 443
rpk cluster config set cloud_storage_region us-east4
rpk cluster config set cloud_storage_bucket <bucket-name>

# Enable cloud topics (v26.1 GA property)
rpk cluster config set cloud_topics_enabled true

# Required: keep archival storage enabled (cloud topics depends on it)
# Do NOT set cloud_storage_enable_remote_write=false or cloud_storage_enable_remote_read=false
# Doing so causes an assertion crash: 'archival_storage_enabled()' cloud topics requires archival storage

# Disable partition auto-balancer (interferes with manual partition placement)
rpk cluster config set partition_autobalancing_mode off

# WAN-tuned raft settings
rpk cluster config set raft_heartbeat_interval_ms 500
rpk cluster config set election_timeout_ms 5000

# Rack awareness (required for rack labels to be recognized)
rpk cluster config set enable_rack_awareness true
```

### Topic Properties

```bash
# Create a cloud topic (v26.1 GA syntax)
rpk topic create <name> -c redpanda.storage.mode=cloud -p <partitions> -r 1

# Cloud topics flush settings (control produce latency)
# flush.ms=100 (default) — flush to GCS every 100ms
# flush.bytes=262144 (default) — or when 256KB accumulated, whichever first
# Increase these for higher-latency regions:
rpk topic alter-config <name> -s flush.ms=500
rpk topic alter-config <name> -s flush.bytes=524288
```

### Ansible Role Variables

The `redpanda.cluster.redpanda_broker` role uses specific variable names for cloud storage:

```yaml
# In provision-cluster.yml vars:
tiered_storage_bucket_name: "{{ gcs_bucket_name }}"          # NOT cloud_storage_bucket
cloud_storage_credentials_source: gcp_instance_metadata       # Auto-sets endpoint to storage.googleapis.com
cloud_storage_region: "{{ cloud_storage_region }}"
```

**Important:** The role uses `tiered_storage_bucket_name` (not `cloud_storage_bucket`) to set the bucket. When `cloud_storage_credentials_source` is `gcp_instance_metadata`, the role automatically sets `cloud_storage_api_endpoint` to `storage.googleapis.com` and enables `cloud_storage_enabled`.

### Version Differences

| Property | v25.3 (beta) | v26.1 (GA) |
|----------|-------------|------------|
| Cluster enable | `unstable_beta_feature_cloud_topics_enabled` | `cloud_topics_enabled` |
| Topic enable | `redpanda.cloud_topic.enabled=true` | `redpanda.storage.mode=cloud` |

## Verification

After deployment:

```bash
# Check cluster health (all 6 nodes should be listed)
ssh <broker> 'rpk cluster health'

# Verify cloud topics enabled
ssh <broker> 'rpk cluster config get cloud_topics_enabled'

# Check topic details and partition placement
ssh <broker> 'rpk topic describe ct-us -p'

# Verify GCS bucket has data
gsutil ls gs://<bucket-name>/

# Produce from each region and measure latency
ssh <us-broker> 'echo test | rpk topic produce ct-us'
ssh <eu-broker> 'echo test | rpk topic produce ct-eu --brokers <eu-private-ip>:9092'
ssh <kr-broker> 'echo test | rpk topic produce ct-kr --brokers <kr-private-ip>:9092'

# Cross-region consume (data available via GCS)
ssh <us-broker> 'rpk topic consume ct-eu'

# Check Grafana dashboards
open http://<monitor-ip>:3000  # admin / redpanda-mrc
```

## Performance Testing

```bash
# Set up performance test environment
ansible-playbook ansible/perf-test-setup.yml

# Run benchmarks
./scripts/run-perf-tests.sh

# Clean up perf tests
ansible-playbook ansible/perf-test-cleanup.yml
```

## Lessons Learned

### 1. RF=1 for Cloud Topics

Cloud Topics durability comes from GCS, not raft replication. RF=1 is sufficient and eliminates cross-region replication overhead. RF=3 with `acks=all` causes 200ms+ produce latency from cross-region raft consensus and can timeout for distant regions.

### 2. Leader Pinning Does Not Work with RF=1

`redpanda.leaders.preference` only selects a leader from existing replicas — it cannot move the replica. With RF=1, the single replica IS the leader. Use `rpk cluster partitions move` to physically place partitions on specific brokers.

### 3. Partition Auto-Balancer Must Be Disabled

The partition auto-balancer (`partition_autobalancing_mode`) interferes with manual partition placement and can stall with cross-region topologies. Set to `off` for this deployment pattern.

### 4. Do NOT Disable Archival Storage with Cloud Topics

Setting `cloud_storage_enable_remote_write=false` or `cloud_storage_enable_remote_read=false` causes an assertion failure crash loop: `'archival_storage_enabled()' cloud topics currently requires archival storage to be enabled`. Leave both at their defaults (`true`).

### 5. GCS Bucket Location Affects Produce Latency

The GCS bucket is located in US multi-region. Produce latency from each region is directly proportional to the broker's distance from GCS:
- US: ~350ms (local)
- EU: ~550ms (~100ms GCS RTT)
- Korea: ~770ms (~200ms GCS RTT)

For production, consider a GCS dual-region bucket covering the two most latency-sensitive regions, or separate buckets per region (which would require multiple clusters — see Option A in the reference architecture).

### 6. Rack Awareness Must Be Explicitly Enabled

After a data wipe or fresh cluster creation, `enable_rack_awareness` defaults to `false`. It must be set to `true` for rack labels to be recognized by the system. Without it, leader pinning and follower fetching cannot function.

### 7. Cross-Region Consume with RF=1

With RF=1, consumers must connect to the broker holding the partition — there is no local replica for follower fetching. Cross-region consumption works via Kafka protocol redirect to the leader, but latency includes the cross-region round trip. For local reads, use RF=3 (with the trade-off of cross-region raft replication on the write path).

## Key Findings

This demo validates the **stretch cluster with cloud topics** architecture. Key findings:

| Question | Answer |
|----------|--------|
| Does Cloud Topics work with GCS multi-region? | **Yes** — validated on v26.1.1-rc4 |
| What is produce latency? | 280ms–986ms depending on GCS distance |
| Can RF=1 be used? | **Yes** — GCS provides durability. Recommended for cloud topics |
| Does leader pinning work with RF=1? | **No** — use `rpk cluster partitions move` instead |
| Can consumers read cross-region? | Yes, via leader redirect. Latency includes cross-region hop |
| Is follower fetching possible? | Only with RF>1. RF=1 has no local replica to fetch from |

### Optimal Pattern for Multi-Region Cloud Topics

Per-region topics with RF=1, partitions manually placed on regional brokers. Producers write to their local broker, GCS provides cross-region durability. Consumers connect to the broker holding the partition, or accept cross-region latency for cross-region reads.

## Estimated Cost

~$35-60/day running 10 GCE instances across 3 regions. Tear down when not in use.
