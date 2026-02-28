#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*"; }

echo ""
warn "This will destroy ALL MRC Cloud Topics demo infrastructure!"
echo ""
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

log "Destroying Terraform infrastructure..."
cd "$PROJECT_DIR/terraform"
terraform destroy -auto-approve

log "Cleaning up generated artifacts..."
rm -f "$PROJECT_DIR/artifacts/hosts_mrc.ini"
rm -f "$PROJECT_DIR/artifacts/envoy_vars.yml"

echo ""
log "Teardown complete."
