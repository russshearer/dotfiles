#!/usr/bin/env bash
###############################################################################
# update-system.sh — Update and clean up packages on Ubuntu or Fedora,
#                     with an optional full distribution/release upgrade.
#
# Usage:
#   sudo ./update-system.sh                # update + clean up all packages
#   sudo ./update-system.sh --dist-upgrade # also perform a release upgrade
#   sudo ./update-system.sh --force        # skip confirmation prompts
#   ./update-system.sh                     # non-root: what-if (list updates only)
#   sudo ./update-system.sh --help
###############################################################################
set -euo pipefail

# ── Configuration ───────────────────────────────────────────────────
LOG_FILE="${LOG_FILE:-/var/log/update-system.log}"
DIST_UPGRADE=0
FORCE=0
WHATIF=0

# ── Colors ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

# ── Helpers ──────────────────────────────────────────────────────────────────
timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

log() {
    echo -e "${BLUE}[$(timestamp)]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() { echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "${RED}[x]${NC} $*" | tee -a "$LOG_FILE" >&2; }

die() {
    log_error "$*"
    exit 1
}

# Ask for confirmation unless --force is set. Returns 0 to proceed.
confirm() {
    local prompt="$1"
    if [[ "$FORCE" -eq 1 ]]; then
        log "$prompt (auto-confirmed via --force)"
        return 0
    fi
    read -rp "$(echo -e "${YELLOW}[?]${NC} ${prompt} [y/N] ")" reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

usage() {
    cat <<EOF
${BOLD}update-system.sh${NC} — Update and clean up packages on Ubuntu or Fedora.

Usage:
  sudo $0 [options]

Options:
  -d, --dist-upgrade   Perform a full distribution/release upgrade after
                       the regular package update and cleanup.
  -n, --what-if        Only check and display available updates; make no
                       changes. This is also the default when not run as root.
  -f, --force          Skip all confirmation prompts and auto-accept.
  -h, --help           Show this help and exit.

Without options, the script only updates and cleans up installed packages.
EOF
}

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dist-upgrade)      DIST_UPGRADE=1; shift ;;
        -n|--what-if|--dry-run) WHATIF=1; shift ;;
        -f|--force)             FORCE=1; shift ;;
        -h|--help)              usage; exit 0 ;;
        *)                      die "Unknown option: $1 (use --help)" ;;
    esac
done

# ── Pre-flight checks ────────────────────────────────────────────────────────
# Non-root runs (or --what-if) fall back to a read-only "what-if": check and
# display available updates without changing anything.
DRY_RUN=0
if [[ $EUID -ne 0 || $WHATIF -eq 1 ]]; then
    DRY_RUN=1
fi

# Fall back to a user-writable log if the default path isn't writable.
if ! { : >>"$LOG_FILE"; } 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/update-system.log"
fi

# ── Detect Linux distribution ────────────────────────────────────────────────
detect_distro() {
    [[ -f /etc/os-release ]] || die "Cannot detect Linux distribution (missing /etc/os-release)."
    . /etc/os-release
    case "$ID" in
        ubuntu|debian) echo "ubuntu" ;;
        fedora)        echo "fedora" ;;
        *)             die "Unsupported distribution: ${ID:-unknown}" ;;
    esac
}

# ── Ubuntu: update + clean up ────────────────────────────────────────────────
update_ubuntu() {
    export DEBIAN_FRONTEND=noninteractive

    log "Updating package lists..."
    apt-get update -y 2>&1 | tee -a "$LOG_FILE"

    log "Upgrading installed packages..."
    apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"

    log "Applying full-upgrade (dependency changes)..."
    apt-get full-upgrade -y 2>&1 | tee -a "$LOG_FILE"

    log "Removing unused packages..."
    apt-get autoremove --purge -y 2>&1 | tee -a "$LOG_FILE"

    log "Cleaning package cache..."
    apt-get autoclean -y 2>&1 | tee -a "$LOG_FILE"

    log_success "Ubuntu packages updated and cleaned up."
}

# ── Fedora: update + clean up ────────────────────────────────────────────────
update_fedora() {
    log "Refreshing metadata and upgrading packages..."
    dnf upgrade --refresh -y 2>&1 | tee -a "$LOG_FILE"

    log "Removing unused packages..."
    dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"

    log "Cleaning package cache..."
    dnf clean all 2>&1 | tee -a "$LOG_FILE"

    log_success "Fedora packages updated and cleaned up."
}

# ── Ubuntu: distribution/release upgrade ─────────────────────────────────────
dist_upgrade_ubuntu() {
    log "Starting Ubuntu release upgrade..."
    if ! command -v do-release-upgrade >/dev/null 2>&1; then
        log "Installing ubuntu-release-upgrader-core..."
        apt-get install -y ubuntu-release-upgrader-core 2>&1 | tee -a "$LOG_FILE"
    fi
    # -f DistUpgradeViewNonInteractive avoids interactive prompts.
    do-release-upgrade -f DistUpgradeViewNonInteractive 2>&1 | tee -a "$LOG_FILE"
    log_success "Ubuntu release upgrade finished."
}

# ── Fedora: distribution/release upgrade ─────────────────────────────────────
dist_upgrade_fedora() {
    log "Starting Fedora release upgrade..."
    . /etc/os-release
    local current="${VERSION_ID}"
    local target=$(( current + 1 ))

    if ! dnf -q repoquery dnf-plugin-system-upgrade >/dev/null 2>&1; then
        log "Installing dnf system-upgrade plugin..."
        dnf install -y dnf-plugin-system-upgrade 2>&1 | tee -a "$LOG_FILE"
    fi

    log "Downloading packages for Fedora ${target} (from ${current})..."
    dnf system-upgrade download --releasever="$target" -y 2>&1 | tee -a "$LOG_FILE"

    log_warn "Packages downloaded. The system must reboot to apply the upgrade."
    log_warn "Run: sudo dnf system-upgrade reboot"
}

# ── Ubuntu: what-if (read-only, no root) ─────────────────────────────────────
check_ubuntu() {
    log "Checking for available updates (using existing package cache)..."
    log_warn "Cache is not refreshed without root; results may be stale."
    local upgradable
    upgradable=$(apt list --upgradable 2>/dev/null | grep -v '^Listing' || true)
    if [[ -z "$upgradable" ]]; then
        log_success "No upgradable packages found in the current cache."
    else
        log_warn "$(echo "$upgradable" | wc -l) package(s) can be upgraded:"
        echo "$upgradable" | tee -a "$LOG_FILE"
    fi
}

# ── Fedora: what-if (read-only, no root) ─────────────────────────────────────
check_fedora() {
    log "Checking for available updates..."
    # dnf check-update exits 100 when updates exist, 0 when none.
    local rc=0
    dnf check-update 2>&1 | tee -a "$LOG_FILE" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        log_success "No updates available."
    elif [[ "$rc" -eq 100 ]]; then
        log_warn "Updates are available (listed above)."
    else
        log_error "Failed to check for updates (dnf exit code $rc)."
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    local distro
    distro=$(detect_distro)

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "========== What-if check (distro: $distro) =========="
        case "$distro" in
            ubuntu) check_ubuntu ;;
            fedora) check_fedora ;;
        esac
        [[ $EUID -eq 0 ]] && log "What-if only; no changes made." \
                          || log "Read-only check complete. Re-run with sudo to apply changes."
        return 0
    fi

    log "========== System update started (distro: $distro) =========="

    case "$distro" in
        ubuntu) update_ubuntu ;;
        fedora) update_fedora ;;
    esac

    if [[ "$DIST_UPGRADE" -eq 1 ]]; then
        if confirm "Proceed with a full distribution/release upgrade?"; then
            case "$distro" in
                ubuntu) dist_upgrade_ubuntu ;;
                fedora) dist_upgrade_fedora ;;
            esac
        else
            log "Skipping distribution upgrade."
        fi
    fi

    log "========== System update completed =========="

    if [[ -f /var/run/reboot-required ]]; then
        log_warn "*** A system reboot is required to apply all updates. ***"
        log_warn "    Run: sudo reboot"
    fi

    log "Full log available at: $LOG_FILE"
}

main "$@"
