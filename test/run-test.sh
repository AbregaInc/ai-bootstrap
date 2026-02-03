#!/bin/bash

# Test the bootstrap script in a fresh macOS VM using Tart
# Self-bootstrapping: installs Homebrew and Tart if needed

set -e

VM_NAME="bootstrap-test"
BASE_IMAGE="ghcr.io/cirruslabs/macos-sequoia-base:latest"

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

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🧪 Bootstrap Script Test Environment${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This test script requires macOS (for Tart VMs)."
    exit 1
fi

# Check Apple Silicon (Tart requires it)
if [[ "$(uname -m)" != "arm64" ]]; then
    print_error "Tart requires Apple Silicon (M1/M2/M3). Intel Macs are not supported."
    print_warning "Alternative: Use GitHub Actions for testing (push to repo and check CI)."
    exit 1
fi

# ============================================================================
# LAYER 1: Ensure Homebrew is installed
# ============================================================================
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found."
    print_step "Installing Homebrew (required for Tart)..."
    echo ""
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for this session (Apple Silicon path)
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew installed successfully!"
    else
        print_error "Homebrew installation failed."
        exit 1
    fi
else
    print_success "Homebrew is installed."
fi

# ============================================================================
# LAYER 2: Ensure Tart is installed
# ============================================================================
if ! command -v tart &> /dev/null; then
    print_warning "Tart not found."
    print_step "Installing Tart from GitHub releases..."
    echo ""
    
    # Tart was removed from Homebrew due to license change
    # Install directly from GitHub releases
    print_step "Fetching latest Tart version..."
    TART_VERSION=$(curl -fsSL https://api.github.com/repos/cirruslabs/tart/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    if [[ -z "$TART_VERSION" ]]; then
        print_error "Could not fetch latest Tart version from GitHub."
        exit 1
    fi
    
    TART_TAR_URL="https://github.com/cirruslabs/tart/releases/download/${TART_VERSION}/tart.tar.gz"
    TART_TAR="/tmp/tart.tar.gz"
    TART_APP_DIR="/Applications"
    
    print_step "Downloading Tart ${TART_VERSION}..."
    curl -fsSL -o "$TART_TAR" "$TART_TAR_URL"
    
    print_step "Installing Tart.app to ${TART_APP_DIR}..."
    # Extract to temp, then move .app bundle
    tar -xzf "$TART_TAR" -C /tmp
    
    # Remove old installation if exists
    if [[ -d "${TART_APP_DIR}/tart.app" ]]; then
        sudo rm -rf "${TART_APP_DIR}/tart.app"
    fi
    
    sudo mv /tmp/tart.app "${TART_APP_DIR}/"
    
    # Create symlink in PATH
    sudo ln -sf "${TART_APP_DIR}/tart.app/Contents/MacOS/tart" /usr/local/bin/tart
    
    rm -f "$TART_TAR"
    
    if command -v tart &> /dev/null; then
        print_success "Tart installed successfully!"
    else
        print_error "Tart installation failed."
        print_warning "Try downloading manually from: https://github.com/cirruslabs/tart/releases"
        exit 1
    fi
else
    print_success "Tart is installed: $(tart --version 2>/dev/null || echo 'version unknown')"
fi

# ============================================================================
# LAYER 3: Prepare the VM
# ============================================================================
echo ""

# Check if VM already exists
if tart list | grep -q "$VM_NAME"; then
    print_warning "Existing test VM found."
    echo -e -n "${YELLOW}?${NC} Delete and recreate fresh VM? ${BOLD}[y/n]${NC}: "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        print_step "Deleting existing test VM..."
        tart delete "$VM_NAME"
    else
        print_step "Reusing existing VM..."
        REUSE_VM=true
    fi
fi

if [[ "$REUSE_VM" != "true" ]]; then
    # Check if base image needs to be pulled first
    if ! tart list | grep -q "ghcr.io/cirruslabs/macos-sequoia-base"; then
        print_step "Pulling base macOS image (this downloads ~20GB on first run)..."
        echo "   Image: $BASE_IMAGE"
        echo ""
        print_warning "This may take 10-30 minutes depending on your internet speed."
        print_warning "You'll see download progress below:"
        echo ""
        
        tart pull "$BASE_IMAGE"
        
        echo ""
        print_success "Base image downloaded!"
    fi
    
    print_step "Cloning VM from base image..."
    tart clone "$BASE_IMAGE" "$VM_NAME"
    print_success "VM created!"
fi

# ============================================================================
# LAYER 4: Start VM and provide instructions
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  📋 Testing Instructions${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}VM Credentials:${NC} user 'admin', password 'admin'"
echo ""
echo -e "  ${BOLD}Once the VM desktop appears:${NC}"
echo ""
echo -e "  1. Open Terminal: Press ${BOLD}Cmd+Space${NC}, type 'Terminal', press Enter"
echo ""
echo "  2. Run the bootstrap script:"
echo ""
echo -e "     ${GREEN}bash '/Volumes/My Shared Files/bootstrap.sh'${NC}"
echo ""
echo "  3. Walk through each step:"
echo "     • Homebrew installation"
echo "     • Git setup (enter name/email)"
echo "     • NVM + Node.js LTS"
echo "     • GitHub CLI + authentication"
echo "     • Choose AI tools to install"
echo ""
echo "  4. Verify everything worked:"
echo ""
echo -e "     ${GREEN}brew --version && git --version && node --version && gh --version${NC}"
echo ""
echo "  5. Close VM window when done (or Ctrl+C here)"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

print_step "Starting VM with shared directory and bridged networking..."
print_success "bootstrap.sh will be available at: /Volumes/My Shared Files/bootstrap.sh"
echo ""

# Get the active network interface
ACTIVE_IF=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
if [[ -z "$ACTIVE_IF" ]]; then
    ACTIVE_IF="en0"
fi

print_info "Using network interface: $ACTIVE_IF"
echo ""

# Run VM with shared directory and bridged networking for full internet access
tart run --dir="$SCRIPT_DIR" --net-bridged="$ACTIVE_IF" "$VM_NAME"

# ============================================================================
# LAYER 5: Cleanup prompt
# ============================================================================
echo ""
echo -e -n "${YELLOW}?${NC} Delete test VM to free disk space? ${BOLD}[y/n]${NC}: "
read -r cleanup
if [[ "$cleanup" =~ ^[Yy]$ ]]; then
    print_step "Deleting test VM..."
    tart delete "$VM_NAME"
    print_success "VM deleted!"
else
    print_warning "VM kept. Run 'tart delete $VM_NAME' later to free space."
fi

echo ""
print_success "Test session complete!"
