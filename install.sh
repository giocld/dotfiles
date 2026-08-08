#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# ==========================
# CONFIGURATION
# ==========================
readonly REPO_URL="https://github.com/giocld/dotifles.git"
readonly DOTDIR="${HOME}/.cfg"
readonly BACKUP_DIR="${HOME}/.config_backup_$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${HOME}/.cache"
readonly LOG_FILE="${LOG_DIR}/dotifles-install-$(date +%Y%m%d_%H%M%S).log"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly FONTS_DIR="${HOME}/.local/share/fonts"
readonly WALLPAPERS_DIR="${HOME}/Pictures/Wallpapers"
readonly SDDM_THEMES_DIR="${HOME}/.local/share/sddm/themes"

# AUR helper choice (set in choose_aur_helper)
AUR_HELPER=""

# Progress tracking
CURRENT_STEP=0
readonly TOTAL_STEPS=9

# Summary tracking
declare -a INSTALL_SUMMARY=()

# sudo keep-alive PID
SUDO_PID=""

# ==========================
# COLOR OUTPUT
# ==========================
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# ==========================
# LOGGING
# ==========================
log() {
  local ts
  ts="$(date +'%Y-%m-%d %H:%M:%S')"
  printf "[%s] %s\n" "${ts}" "$*" >> "${LOG_FILE}" 2>/dev/null || true
}
msg()   { printf "${GREEN}==>${NC} %s\n" "$1"; log "INFO: $1"; }
info()  { printf "${BLUE}==>${NC} %s\n" "$1"; log "INFO: $1"; }
warn()  { printf "${YELLOW}[WARNING]${NC} %s\n" "$1"; log "WARNING: $1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; log "ERROR: $1"; }
fatal() { error "$1"; error "Installation failed. Log: ${LOG_FILE}"; exit 1; }

step() {
  ((++CURRENT_STEP)) || true
  printf "\n${CYAN}${BOLD}[Step %d/%d]${NC} ${MAGENTA}%s${NC}\n" \
    "${CURRENT_STEP}" "${TOTAL_STEPS}" "$1"
  printf "${CYAN}─────────────────────────────────────────────────────${NC}\n"
  log "STEP ${CURRENT_STEP}/${TOTAL_STEPS}: $1"
}

add_summary() { INSTALL_SUMMARY+=("$1"); }

usage() {
  cat << EOF
Usage: ${0##*/} [OPTIONS]

Full device recreation from the giocld/dotifles bare-repo dotfiles.

OPTIONS:
  -h, --help   Show this help and exit

REQUIREMENTS:
  - Arch-based distro (pacman)
  - Internet connection, sudo access
  - ~5GB free space for packages

INSTALLS:
  - All packages from packages.txt + packages-aur.txt (same dir as script)
  - Bare-clones dotfiles to ~/.cfg and checks out into \$HOME
  - Miracode font, SilentSDDM theme, wallpapers (via awww)
  - GTK themes/icons (Colloid, Osaka, Rosepine) — best effort
  - Enables systemd user services from the repo

LOG FILE: ${LOG_FILE}
EOF
}
