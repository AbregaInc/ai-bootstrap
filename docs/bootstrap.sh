#!/bin/bash

# AI Development Environment Bootstrap Script
# This script helps you set up everything you need to start coding with AI tools

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Helper functions
print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

ask_yes_no() {
    while true; do
        echo -e -n "${YELLOW}?${NC} $1 ${BOLD}[y/n]${NC}: "
        read -r answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "  Please answer y (yes) or n (no).";;
        esac
    done
}

press_enter() {
    echo ""
    echo -e -n "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script is designed for macOS. You appear to be running a different OS."
        exit 1
    fi
}

# Welcome message
show_welcome() {
    clear
    echo ""
    echo -e "${PURPLE}"
    echo "    ╔═══════════════════════════════════════════════════════════╗"
    echo "    ║                                                           ║"
    echo "    ║   🚀  AI Development Environment Bootstrap  🚀            ║"
    echo "    ║                                                           ║"
    echo "    ║   This script will help you set up:                       ║"
    echo "    ║                                                           ║"
    echo "    ║   • Homebrew (package manager)                            ║"
    echo "    ║   • Git (version control)                                 ║"
    echo "    ║   • NVM + Node.js LTS                                     ║"
    echo "    ║   • GitHub CLI + Authentication                          ║"
    echo "    ║   • AI Coding Tools (Codex, OpenCode, Claude Code)        ║"
    echo "    ║                                                           ║"
    echo "    ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    print_info "Don't worry - we'll explain each step along the way!"
    echo ""
    
    if ! ask_yes_no "Ready to get started?"; then
        echo ""
        print_info "No problem! Run this script again when you're ready."
        exit 0
    fi
}

# Install Homebrew
install_homebrew() {
    print_header "Step 1: Installing Homebrew"
    
    echo "Homebrew is a package manager for macOS. Think of it like an app store"
    echo "for developer tools - it makes installing and updating software easy."
    echo ""
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew is already installed!"
        print_step "Updating Homebrew to latest version..."
        brew update
        print_success "Homebrew updated!"
    else
        print_step "Installing Homebrew..."
        echo ""
        print_info "You may be asked for your password. This is your Mac login password."
        print_info "When you type it, you won't see any characters - that's normal!"
        echo ""
        
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed successfully!"
    fi
    
    press_enter
}

# Install Git
install_git() {
    print_header "Step 2: Installing Git"
    
    echo "Git is version control software. It helps you track changes to your code"
    echo "and collaborate with others. Almost every developer uses Git!"
    echo ""
    
    if command -v git &> /dev/null; then
        print_success "Git is already installed!"
        git --version
    else
        print_step "Installing Git via Homebrew..."
        brew install git
        print_success "Git installed successfully!"
    fi
    
    echo ""
    print_step "Configuring Git..."
    
    # Check if git is configured
    if [[ -z "$(git config --global user.name)" ]]; then
        echo ""
        print_info "Git needs to know who you are for commit messages."
        echo -e -n "${YELLOW}?${NC} Enter your name (e.g., John Smith): "
        read -r git_name
        git config --global user.name "$git_name"
        print_success "Name set!"
    else
        print_success "Git name already configured: $(git config --global user.name)"
    fi
    
    if [[ -z "$(git config --global user.email)" ]]; then
        echo -e -n "${YELLOW}?${NC} Enter your email (use your GitHub email if you have one): "
        read -r git_email
        git config --global user.email "$git_email"
        print_success "Email set!"
    else
        print_success "Git email already configured: $(git config --global user.email)"
    fi
    
    press_enter
}

# Install NVM and Node.js
install_nvm_node() {
    print_header "Step 3: Installing NVM and Node.js"
    
    echo "NVM (Node Version Manager) lets you install and switch between different"
    echo "versions of Node.js. Node.js is required for many AI coding tools."
    echo ""
    
    export NVM_DIR="$HOME/.nvm"
    
    if [[ -d "$NVM_DIR" ]]; then
        print_success "NVM is already installed!"
        # Load NVM
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        print_step "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        
        # Load NVM immediately
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        print_success "NVM installed successfully!"
    fi
    
    echo ""
    print_step "Installing Node.js LTS (Long Term Support)..."
    print_info "LTS versions are stable and recommended for most users."
    echo ""
    
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    echo ""
    print_success "Node.js installed!"
    print_info "Node version: $(node --version)"
    print_info "NPM version: $(npm --version)"
    
    press_enter
}

# Install GitHub CLI
install_github_cli() {
    print_header "Step 4: Installing GitHub CLI"
    
    echo "GitHub CLI (gh) lets you interact with GitHub from your terminal."
    echo "It makes authentication and many GitHub tasks much easier!"
    echo ""
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI is already installed!"
        gh --version
    else
        print_step "Installing GitHub CLI via Homebrew..."
        brew install gh
        print_success "GitHub CLI installed successfully!"
    fi
    
    press_enter
}

# GitHub Authentication
setup_github_auth() {
    print_header "Step 5: GitHub Authentication"
    
    echo "Now we'll connect your terminal to your GitHub account."
    echo ""
    
    # Check if already authenticated
    if gh auth status &> /dev/null; then
        print_success "You're already authenticated with GitHub!"
        gh auth status
        echo ""
        if ! ask_yes_no "Would you like to re-authenticate anyway?"; then
            return
        fi
    fi
    
    echo ""
    print_info "This will open a web browser for you to log in to GitHub."
    print_info "If you don't have a GitHub account, create one at https://github.com"
    echo ""
    
    if ask_yes_no "Ready to authenticate with GitHub?"; then
        echo ""
        print_step "Starting GitHub authentication..."
        print_info "A browser window will open. Follow the prompts there."
        echo ""
        
        gh auth login --web -h github.com
        
        echo ""
        print_success "GitHub authentication complete!"
    else
        print_warning "Skipping GitHub authentication."
        print_info "You can run 'gh auth login' later to authenticate."
    fi
    
    press_enter
}

# Install AI Coding Tools
install_ai_tools() {
    print_header "Step 6: AI Coding Tools"
    
    echo "Now for the fun part! Choose which AI coding assistants to install."
    echo ""
    echo -e "${CYAN}Available tools:${NC}"
    echo ""
    echo -e "  ${BOLD}1. Codex CLI${NC} (by OpenAI)"
    echo "     Command-line AI assistant from the creators of ChatGPT"
    echo ""
    echo -e "  ${BOLD}2. OpenCode${NC} (by Inference Labs)"
    echo "     Open-source AI coding assistant"
    echo ""
    echo -e "  ${BOLD}3. Claude Code${NC} (by Anthropic)"
    echo "     AI coding assistant from the creators of Claude"
    echo ""
    
    # Codex CLI
    echo ""
    if ask_yes_no "Install Codex CLI?"; then
        print_step "Installing Codex CLI..."
        npm install -g @openai/codex
        print_success "Codex CLI installed!"
        print_info "Run 'codex' to start using it. You'll need an OpenAI API key."
    fi
    
    # OpenCode
    echo ""
    if ask_yes_no "Install OpenCode?"; then
        print_step "Installing OpenCode..."
        npm install -g @anthropics/opencode
        print_success "OpenCode installed!"
        print_info "Run 'opencode' to start using it."
    fi
    
    # Claude Code
    echo ""
    if ask_yes_no "Install Claude Code?"; then
        print_step "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        print_success "Claude Code installed!"
        print_info "Run 'claude' to start using it. You'll need an Anthropic API key."
    fi
    
    press_enter
}

# Show completion message
show_completion() {
    clear
    echo ""
    echo -e "${GREEN}"
    echo "    ╔═══════════════════════════════════════════════════════════╗"
    echo "    ║                                                           ║"
    echo "    ║   🎉  Setup Complete!  🎉                                 ║"
    echo "    ║                                                           ║"
    echo "    ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    print_header "What's Installed"
    
    echo -e "${BOLD}Core Tools:${NC}"
    command -v brew &> /dev/null && print_success "Homebrew: $(brew --version | head -1)"
    command -v git &> /dev/null && print_success "Git: $(git --version)"
    command -v node &> /dev/null && print_success "Node.js: $(node --version)"
    command -v npm &> /dev/null && print_success "NPM: $(npm --version)"
    command -v gh &> /dev/null && print_success "GitHub CLI: $(gh --version | head -1)"
    
    echo ""
    echo -e "${BOLD}AI Coding Tools:${NC}"
    command -v codex &> /dev/null && print_success "Codex CLI"
    command -v opencode &> /dev/null && print_success "OpenCode"
    command -v claude &> /dev/null && print_success "Claude Code"
    
    echo ""
    print_header "Next Steps"
    
    echo "1. ${BOLD}Open a new terminal${NC} to ensure all changes take effect"
    echo ""
    echo "2. ${BOLD}Get API keys${NC} for the AI tools you installed:"
    echo "   • OpenAI (for Codex): https://platform.openai.com/api-keys"
    echo "   • Anthropic (for Claude): https://console.anthropic.com/"
    echo ""
    echo "3. ${BOLD}Start coding!${NC} Try running one of the AI tools in a project directory."
    echo ""
    
    print_info "Happy coding! 🚀"
    echo ""
}

# Main script
main() {
    check_macos
    show_welcome
    install_homebrew
    install_git
    install_nvm_node
    install_github_cli
    setup_github_auth
    install_ai_tools
    show_completion
}

main
