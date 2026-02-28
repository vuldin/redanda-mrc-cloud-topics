#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*"; }
err() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $*" >&2; }

# --- Configuration ---
export ANSIBLE_COLLECTIONS_PATH="${PROJECT_DIR}/artifacts/collections"
export ANSIBLE_ROLES_PATH="${PROJECT_DIR}/artifacts/roles"
export ANSIBLE_INVENTORY="${PROJECT_DIR}/artifacts/hosts_mrc.ini"
export ANSIBLE_HOST_KEY_CHECKING=False

# --- Pre-flight checks ---
log "Running pre-flight checks..."

for cmd in terraform ansible-playbook ansible-galaxy aws; do
  if ! command -v "$cmd" &>/dev/null; then
    err "$cmd is required but not installed"
    exit 1
  fi
done

if [ -z "${REDPANDA_LICENSE:-}" ]; then
  warn "REDPANDA_LICENSE not set — cloud topics require an enterprise license"
fi

# --- Step 1: Terraform ---
log "Step 1/7: Applying Terraform infrastructure..."
cd "$PROJECT_DIR/terraform"
terraform init
terraform apply -auto-approve

# Wait for instances to be ready
log "Waiting 60s for instances to initialize..."
sleep 60

# --- Step 2: Install Ansible requirements ---
log "Step 2/7: Installing Ansible Galaxy requirements..."
mkdir -p "$ANSIBLE_COLLECTIONS_PATH" "$ANSIBLE_ROLES_PATH"
ansible-galaxy collection install -r "$PROJECT_DIR/ansible/requirements.yml" \
  --force -p "$ANSIBLE_COLLECTIONS_PATH"
ansible-galaxy role install -r "$PROJECT_DIR/ansible/requirements.yml" \
  --force -p "$ANSIBLE_ROLES_PATH"

# --- Step 3: Deploy Envoy proxies ---
log "Step 3/7: Deploying Envoy SigV4A proxies..."
ansible-playbook "$PROJECT_DIR/ansible/deploy-envoy.yml"

# --- Step 4: Provision Redpanda cluster ---
log "Step 4/7: Provisioning Redpanda cluster..."
ansible-playbook "$PROJECT_DIR/ansible/provision-cluster.yml"

# --- Step 5: Configure Cloud Topics ---
log "Step 5/7: Configuring Cloud Topics..."
ansible-playbook "$PROJECT_DIR/ansible/configure-cloud-topics.yml"

# --- Step 6: Deploy monitoring ---
log "Step 6/7: Deploying monitoring stack..."
ansible-playbook "$PROJECT_DIR/ansible/deploy-monitor.yml"

# --- Step 7: Deploy workload generators ---
log "Step 7/7: Deploying workload generators..."
ansible-playbook "$PROJECT_DIR/ansible/deploy-workload.yml"

# --- Summary ---
cd "$PROJECT_DIR/terraform"
GRAFANA_URL=$(terraform output -raw grafana_url)
PROMETHEUS_URL=$(terraform output -raw prometheus_url)
MRAP_ENDPOINT=$(terraform output -raw mrap_endpoint)

echo ""
echo "============================================"
log "MRC Cloud Topics Demo deployed successfully!"
echo "============================================"
echo ""
echo "Grafana:    $GRAFANA_URL (admin / redpanda-mrc)"
echo "Prometheus: $PROMETHEUS_URL"
echo "MRAP:       $MRAP_ENDPOINT"
echo ""
echo "SSH to first US broker:"
echo "  $(terraform output -json ssh_commands | jq -r '.broker_us[0]')"
echo ""
echo "Verify cluster health:"
echo "  ssh <broker> 'rpk cluster health'"
echo "  ssh <broker> 'rpk topic describe demo-cloud-topic'"
echo ""
echo "Verify Envoy proxy:"
echo "  ssh <broker> 'curl -s http://localhost:9901/stats | grep s3_mrap'"
echo ""
