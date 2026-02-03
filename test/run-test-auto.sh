#!/bin/bash

# Fully automated test of bootstrap script in a Tart macOS VM
# Runs headless with SSH - no manual interaction required

set -e

VM_NAME="bootstrap-test-auto"
BASE_IMAGE="ghcr.io/cirruslabs/macos-sequoia-base:latest"
VM_USER="admin"
VM_PASS="admin"
SSH_PORT=22
MAX_WAIT=300  # Max seconds to wait for VM to be ready

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

print_step() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }

cleanup() {
    if [[ -n "$VM_PID" ]]; then
        print_step "Stopping VM..."
        kill "$VM_PID" 2>/dev/null || true
        wait "$VM_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🤖 Automated Bootstrap Script Test${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check requirements
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This test script requires macOS."
    exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
    print_error "Tart requires Apple Silicon."
    exit 1
fi

if ! command -v tart &> /dev/null; then
    print_error "Tart not installed. Run ./test/run-test.sh first to install it."
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ============================================================================
# Prepare VM
# ============================================================================

# Delete existing VM if present
if tart list | grep -q "$VM_NAME"; then
    print_step "Deleting existing test VM..."
    tart delete "$VM_NAME"
fi

# Pull base image if needed
if ! tart list | grep -q "ghcr.io/cirruslabs/macos-sequoia-base"; then
    print_step "Pulling base macOS image (this downloads ~20GB on first run)..."
    tart pull "$BASE_IMAGE"
fi

print_step "Cloning VM from base image..."
tart clone "$BASE_IMAGE" "$VM_NAME"
print_success "VM created!"

# ============================================================================
# Start VM headless
# ============================================================================

print_step "Starting VM in headless mode..."

# Start VM in background with SSH forwarding
tart run --no-graphics --dir="$SCRIPT_DIR" "$VM_NAME" &
VM_PID=$!

print_info "VM PID: $VM_PID"

# ============================================================================
# Wait for SSH to be available
# ============================================================================

print_step "Waiting for VM to boot and SSH to become available..."

# Get VM IP
VM_IP=""
WAIT_COUNT=0

while [[ -z "$VM_IP" ]] && [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT + 5))
    VM_IP=$(tart ip "$VM_NAME" 2>/dev/null || true)
    if [[ -n "$VM_IP" ]]; then
        print_info "VM IP: $VM_IP (after ${WAIT_COUNT}s)"
    else
        echo -n "."
    fi
done

if [[ -z "$VM_IP" ]]; then
    print_error "Could not get VM IP after ${MAX_WAIT}s"
    exit 1
fi

# Wait for SSH to accept connections
SSH_READY=false
while [[ "$SSH_READY" != "true" ]] && [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT + 5))
    if nc -z -w 5 "$VM_IP" 22 2>/dev/null; then
        SSH_READY=true
        print_success "SSH is ready! (after ${WAIT_COUNT}s)"
    else
        echo -n "."
    fi
done

if [[ "$SSH_READY" != "true" ]]; then
    print_error "SSH not available after ${MAX_WAIT}s"
    exit 1
fi

# Give SSH a moment to fully initialize
sleep 5

# ============================================================================
# SSH helper function
# ============================================================================

ssh_cmd() {
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$VM_USER@$VM_IP" "$@"
}

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    print_warning "sshpass not found, installing..."
    brew install hudochenkov/sshpass/sshpass
fi

# ============================================================================
# Run automated tests
# ============================================================================

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🧪 Running Bootstrap Script Tests${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 1: Verify shared directory is mounted
print_step "Test 1: Checking shared directory..."
if ssh_cmd "test -f '/Volumes/My Shared Files/bootstrap.sh'"; then
    print_success "Shared directory mounted and bootstrap.sh accessible"
else
    print_error "Shared directory not mounted"
    exit 1
fi

# Test 2: Run bootstrap script with auto-answers
print_step "Test 2: Running bootstrap script (automated)..."
echo ""

# Create an expect-like input file that answers all prompts
# y = start, y = name (use default), y = email (use default), y = gh auth skip, y = ghostty, y = amp, n = codex, y = opencode, n = claude, n = kilo
# The script will auto-configure git with test values

ssh_cmd "bash -c '
# Pre-configure git to avoid prompts
git config --global user.name \"Test User\"
git config --global user.email \"test@example.com\"

# Run bootstrap with pre-filled answers
# Answers: y (start), n (skip gh auth), y (ghostty), y (amp), n (codex), y (opencode), n (claude), n (kilo)
echo -e \"y\\nn\\ny\\ny\\nn\\ny\\nn\\nn\" | bash \"/Volumes/My Shared Files/bootstrap.sh\"
'" 2>&1 | tee /tmp/bootstrap-output.log

echo ""

# Test 3: Verify installations
print_step "Test 3: Verifying installations..."

TESTS_PASSED=0
TESTS_TOTAL=0

check_install() {
    local name="$1"
    local cmd="$2"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if ssh_cmd "$cmd" &>/dev/null; then
        print_success "$name: installed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "$name: NOT installed"
    fi
}

check_install "Homebrew" "command -v /opt/homebrew/bin/brew"
check_install "Git" "command -v git"
check_install "Node.js" "source ~/.nvm/nvm.sh && command -v node"
check_install "NPM" "source ~/.nvm/nvm.sh && command -v npm"
check_install "GitHub CLI" "command -v gh"
check_install "Ghostty" "test -d /Applications/Ghostty.app"
check_install "OpenCode" "source ~/.nvm/nvm.sh && command -v opencode"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  📊 Test Results: ${TESTS_PASSED}/${TESTS_TOTAL} passed${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# Cleanup
# ============================================================================

print_step "Stopping VM..."
kill "$VM_PID" 2>/dev/null || true
wait "$VM_PID" 2>/dev/null || true
VM_PID=""

print_step "Deleting test VM..."
tart delete "$VM_NAME"

echo ""
if [[ $TESTS_PASSED -eq $TESTS_TOTAL ]]; then
    print_success "All tests passed! ✨"
    exit 0
else
    print_error "Some tests failed. Check output above."
    exit 1
fi
