#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*"; }
err()  { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $*" >&2; }
info() { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*"; }

# --- Configuration ---
export ANSIBLE_COLLECTIONS_PATH="${PROJECT_DIR}/artifacts/collections"
export ANSIBLE_ROLES_PATH="${PROJECT_DIR}/artifacts/roles"
export ANSIBLE_INVENTORY="${PROJECT_DIR}/artifacts/hosts_mrc.ini"
export ANSIBLE_HOST_KEY_CHECKING=False

PLAYBOOK_DIR="${PROJECT_DIR}/ansible"
RESULTS_DIR="${PROJECT_DIR}/results"
STEP_DURATION="${STEP_DURATION:-300}"
PHASES="${PHASES:-all}"
SKIP_SETUP="${SKIP_SETUP:-false}"
SKIP_TUNING="${SKIP_TUNING:-false}"
SKIP_CLEANUP="${SKIP_CLEANUP:-false}"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

MRC Cloud Topics Performance Test Runner

Options:
  --phases PHASES     Comma-separated phases to run (1,2,3,4,all) [default: all]
  --step-duration S   Duration per test step in seconds [default: 300]
  --skip-setup        Skip setup phase (tools already installed, topics created)
  --skip-tuning       Skip cluster tuning phase
  --skip-cleanup      Skip cleanup phase
  --help              Show this help

Environment Variables:
  STEP_DURATION       Same as --step-duration
  PHASES              Same as --phases

Examples:
  $0                              # Run everything
  $0 --phases 1,2 --step-duration 60    # Quick Phase 1+2 with 60s steps
  $0 --phases 2 --skip-setup     # Re-run Phase 2 only (setup already done)
EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --phases)       PHASES="$2"; shift 2 ;;
    --step-duration) STEP_DURATION="$2"; shift 2 ;;
    --skip-setup)   SKIP_SETUP=true; shift ;;
    --skip-tuning)  SKIP_TUNING=true; shift ;;
    --skip-cleanup) SKIP_CLEANUP=true; shift ;;
    --help)         usage ;;
    *)              err "Unknown option: $1"; usage ;;
  esac
done

run_playbook() {
  local playbook="$1"
  shift
  log "Running: ansible-playbook $playbook $*"
  ansible-playbook "${PLAYBOOK_DIR}/${playbook}" -e "step_duration=${STEP_DURATION}" "$@"
}

# --- Pre-flight checks ---
log "=========================================="
log "MRC Cloud Topics Performance Test Runner"
log "=========================================="
info "Phases: ${PHASES}"
info "Step duration: ${STEP_DURATION}s"
info "Results directory: ${RESULTS_DIR}"
echo ""

for cmd in ansible-playbook; do
  if ! command -v "$cmd" &>/dev/null; then
    err "$cmd is required but not installed"
    exit 1
  fi
done

if [ ! -f "$ANSIBLE_INVENTORY" ]; then
  err "Inventory file not found: $ANSIBLE_INVENTORY"
  err "Run 'terraform apply' first to generate inventory"
  exit 1
fi

mkdir -p "$RESULTS_DIR"

# Record test start
START_TIME=$(date +%s)
echo "test_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${RESULTS_DIR}/test-metadata.txt"
echo "step_duration=${STEP_DURATION}" >> "${RESULTS_DIR}/test-metadata.txt"
echo "phases=${PHASES}" >> "${RESULTS_DIR}/test-metadata.txt"

# --- Step 1: Validate cluster health ---
log "Step 0: Validating cluster health..."
ansible -m command -a "rpk cluster health" "redpanda[0]" 2>/dev/null || {
  err "Cluster health check failed. Is the cluster running?"
  exit 1
}
log "Cluster is healthy."
echo ""

# --- Step 2: Setup ---
if [ "$SKIP_SETUP" != "true" ]; then
  log "Step 1: Running performance test setup..."
  run_playbook perf-test-setup.yml
  echo ""
else
  info "Skipping setup (--skip-setup)"
fi

# --- Step 3: Cluster tuning ---
if [ "$SKIP_TUNING" != "true" ]; then
  log "Step 2: Applying cluster tuning..."
  run_playbook perf-tune-cluster.yml --tags cloud_storage,kafka_api,system,topics
  echo ""
else
  info "Skipping tuning (--skip-tuning)"
fi

# --- Step 4: Run test phases ---
should_run_phase() {
  local phase="$1"
  [ "$PHASES" = "all" ] && return 0
  echo "$PHASES" | tr ',' '\n' | grep -q "^${phase}$"
}

if should_run_phase 1; then
  log "=========================================="
  log "Phase 1: Hop Isolation"
  log "=========================================="
  run_playbook perf-test-run.yml --tags phase1
  log "Phase 1 complete. Cooldown 60s..."
  sleep 60
fi

if should_run_phase 2; then
  log "=========================================="
  log "Phase 2: Progressive Producer Load Tests"
  log "=========================================="
  run_playbook perf-test-run.yml --tags phase2
  log "Phase 2 complete. Cooldown 60s..."
  sleep 60
fi

if should_run_phase 3; then
  log "=========================================="
  log "Phase 3: Consumer Tests"
  log "=========================================="
  run_playbook perf-test-run.yml --tags phase3
  log "Phase 3 complete. Cooldown 60s..."
  sleep 60
fi

if should_run_phase 4; then
  log "=========================================="
  log "Phase 4: Combined Produce + Consume"
  log "=========================================="
  run_playbook perf-test-run.yml --tags phase4
  log "Phase 4 complete."
fi

# --- Step 5: Collect results ---
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
ELAPSED_MIN=$(( ELAPSED / 60 ))

echo "test_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${RESULTS_DIR}/test-metadata.txt"
echo "elapsed_seconds=${ELAPSED}" >> "${RESULTS_DIR}/test-metadata.txt"

if [ "$SKIP_CLEANUP" != "true" ]; then
  log "Collecting results from all hosts..."
  run_playbook perf-test-cleanup.yml --tags collect
else
  info "Skipping cleanup (--skip-cleanup)"
fi

# --- Summary ---
echo ""
log "=========================================="
log "Performance Test Complete"
log "=========================================="
info "Total time: ${ELAPSED_MIN} minutes (${ELAPSED}s)"
info "Results: ${RESULTS_DIR}/"
info "Metadata: ${RESULTS_DIR}/test-metadata.txt"
echo ""
info "Next steps:"
info "  1. Review results in ${RESULTS_DIR}/"
info "  3. Clean up when done:"
info "     ansible-playbook ansible/perf-test-cleanup.yml"
