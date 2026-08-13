#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[x]${NC} $1" >&2
}

print_header() {
    echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            echo "ubuntu"
        elif [[ "$ID" == "fedora" ]]; then
            echo "fedora"
        else
            log_error "Unsupported distribution: $ID"
            exit 1
        fi
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi
}

# Update package manager
update_packages() {
    local distro=$1
    log_info "Checking for available updates..."

    if [[ "$distro" == "ubuntu" ]]; then
        sudo apt-get update -qq || { log_error "Failed to update apt"; return 1; }
        # Count upgradable packages (excluding the header line)
        local count
        count=$(apt-get -s upgrade 2>/dev/null | grep -c '^Inst ' || true)
        if [[ "$count" -eq 0 ]]; then
            log_success "System is up to date"
            return 0
        fi
        log_warn "$count package(s) can be upgraded"
        apt list --upgradable 2>/dev/null | grep -v '^Listing'
        read -rp "$(echo -e "${YELLOW}[?]${NC} Upgrade them now? [y/N] ")" reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            sudo apt-get upgrade -y -qq || { log_error "Upgrade failed"; return 1; }
            log_success "Ubuntu packages upgraded"
        else
            log_info "Skipping system upgrade"
        fi
    elif [[ "$distro" == "fedora" ]]; then
        # dnf check-update exits 100 when updates are available, 0 when none
        local rc=0
        sudo dnf check-update -q >/dev/null || rc=$?
        if [[ "$rc" -eq 0 ]]; then
            log_success "System is up to date"
            return 0
        elif [[ "$rc" -ne 100 ]]; then
            log_error "Failed to check dnf updates"
            return 1
        fi
        log_warn "Updates are available"
        { sudo dnf check-update -q || true; }
        read -rp "$(echo -e "${YELLOW}[?]${NC} Upgrade them now? [y/N] ")" reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            sudo dnf upgrade -y -q || { log_error "Upgrade failed"; return 1; }
            log_success "Fedora packages upgraded"
        else
            log_info "Skipping system upgrade"
        fi
    fi
}

# Install tools from config file
install_tools() {
    local config_file=$1
    local distro=$2

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Reading tools from: $config_file"
    local failed_tools=()

    while IFS= read -r tool || [[ -n "$tool" ]]; do

        # Skip empty lines and comments
        [[ -z "$tool" || "$tool" =~ ^[[:space:]]*# ]] && continue

        # Strip inline comments (# and anything after)
        tool="${tool%%#*}"

        # Trim whitespace
        tool=$(echo "$tool" | xargs)

        log_info "Installing: $tool"

        if [[ "$distro" == "ubuntu" ]]; then
            if output=$(sudo apt-get install -y -qq "$tool" 2>&1); then
                if [[ "$output" == *"is already the newest version"* ]]; then
                    log_success "Already installed: $tool"
                else
                    log_success "Installed: $tool"
                fi
            else
                log_warn "Failed to install: $tool"
                echo "$output" | sed 's/^/    /'
                failed_tools+=("$tool")
            fi
        elif [[ "$distro" == "fedora" ]]; then
            if output=$(sudo dnf install -y -q "$tool" 2>&1); then
                if [[ "$output" == *"already installed"* ]]; then
                    log_success "Already installed: $tool"
                else
                    log_success "Installed: $tool"
                fi
            else
                log_warn "Failed to install: $tool"
                echo "$output" | sed 's/^/    /'
                failed_tools+=("$tool")
            fi
        fi
    done < "$config_file"

    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        log_warn "Failed to install ${#failed_tools[@]} tool(s):"
        for tool in "${failed_tools[@]}"; do
            echo "  - $tool"
        done
        return 1
    fi

    return 0
}

# Clone/update dotfiles and run the repo's install script
setup_dotfiles() {
    local repo_url="git@github.com:russshearer/dotfiles.git"
    local install_script="install.sh"

    # Run as the invoking user (not root) so their SSH key and file ownership are used
    local target_user="${SUDO_USER:-$USER}"
    local target_home
    target_home=$(getent passwd "$target_user" | cut -d: -f6)
    local dest="$target_home/.dotfiles"

    if ! command -v git >/dev/null 2>&1; then
        log_error "git is not installed; cannot fetch config files"
        return 1
    fi

    # Helper: run a command as the target user
    run_as() { sudo -u "$target_user" -H "$@"; }

    if [[ -d "$dest/.git" ]]; then
        log_info "Updating dotfiles in $dest"
        run_as git -C "$dest" pull --ff-only || { log_error "Failed to update dotfiles"; return 1; }
    else
        log_info "Cloning dotfiles into $dest (as $target_user)"
        run_as git clone "$repo_url" "$dest" || { log_error "Failed to clone dotfiles"; return 1; }
    fi

    if [[ -x "$dest/$install_script" ]]; then
        log_info "Running dotfiles install script"
        run_as bash -c "cd '$dest' && ./$install_script" || { log_error "Dotfiles install script failed"; return 1; }
        log_success "Dotfiles applied"
    else
        log_warn "No executable $install_script found in $dest; skipping"
    fi

    return 0
}

main() {
    print_header "Linux Machine Setup"

    local config_file="${1:-linux_core_setup.conf}"

    log_info "Starting Linux machine setup..."

    # Detect distribution
    local distro
    distro=$(detect_distro)
    log_success "Detected distribution: $distro"

    # Require root; prompt the user to re-run with sudo
    if [[ "$EUID" -ne 0 ]]; then
        log_error "This script needs root privileges."
        log_info "Please re-run it with sudo:"
        echo -e "\n    sudo $0 $*\n"
        exit 1
    fi

    # Update packages
    print_header "Package Manager Update"
    update_packages "$distro" || { log_error "Package update failed"; exit 1; }

    # Install tools
    print_header "Installing Tools"
    if install_tools "$config_file" "$distro"; then
        log_success "All tools installed successfully"
    else
        log_warn "Some tools failed to install"
    fi

    # Fetch and apply config files from git
    print_header "Configuration Files"
    setup_dotfiles || log_warn "Dotfiles setup did not complete"

    print_header "Setup Complete"
    log_success "Linux machine setup finished!"
}

# Trap errors
trap 'log_error "Script failed at line $LINENO"; exit 1' ERR

# Run main function
main "$@"
