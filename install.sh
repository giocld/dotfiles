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

# ==========================
# PRE-FLIGHT CHECKS
# ==========================
check_not_root() {
  if [[ ${EUID} -eq 0 ]]; then
    fatal "Do not run as root. Run as a regular user with sudo."
  fi
}

check_arch_based() {
  if ! command -v pacman &>/dev/null; then
    fatal "pacman not found — this script requires an Arch-based distro."
  fi
  if [[ -f /etc/os-release ]] && grep -qE '^ID=(arch|cachyos)$' /etc/os-release; then
    msg "Arch-based system detected."
  else
    warn "Could not verify distro — continuing on faith that pacman exists."
  fi
}

check_internet() {
  if ! command -v curl &>/dev/null; then
    warn "curl missing — will install with base tools."
    return 0
  fi
  local ok=false
  for ep in "https://archlinux.org" "https://github.com" "https://aur.archlinux.org"; do
    if curl -sf --connect-timeout 5 --max-time 10 "${ep}" >/dev/null 2>&1; then
      ok=true
      break
    fi
  done
  if [[ "${ok}" == "false" ]]; then
    fatal "No internet connection."
  fi
  msg "Internet connection verified."
}

check_sudo() {
  if ! sudo -v; then
    fatal "Sudo required. Ensure the user has sudo rights."
  fi
  ( while sleep 50; do sudo -v || true; done ) &
  SUDO_PID=$!
  msg "Sudo privileges verified (keep-alive started)."
}

cleanup_on_exit() {
  local code=$?
  if [[ -n "${SUDO_PID}" ]] && kill -0 "${SUDO_PID}" 2>/dev/null; then
    kill "${SUDO_PID}" 2>/dev/null || true
  fi
  sudo -k 2>/dev/null || true
  if [[ ${code} -ne 0 ]]; then
    error "Script exited with code ${code}"
  fi
}
trap 'cleanup_on_exit' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# ==========================
# BASE TOOLS & AUR HELPER
# ==========================
install_base_tools() {
  info "Installing base development tools..."
  sudo pacman -S --needed --noconfirm git base-devel curl jq >> "${LOG_FILE}" 2>&1 \
    || fatal "Failed to install base tools."
  msg "Base tools installed (git, base-devel, curl, jq)."
}

choose_aur_helper() {
  if command -v yay &>/dev/null && yay --version &>/dev/null; then
    AUR_HELPER="yay"
    msg "Using existing yay."
    return 0
  fi
  if command -v paru &>/dev/null && paru --version &>/dev/null; then
    AUR_HELPER="paru"
    msg "Using existing paru."
    return 0
  fi
  info "Installing yay from AUR..."
  local tmp
  tmp="$(mktemp -d)"
  if ! git clone --depth=1 https://aur.archlinux.org/yay-bin.git "${tmp}" >> "${LOG_FILE}" 2>&1; then
    rm -rf "${tmp}"
    fatal "Failed to clone yay."
  fi
  if ! (cd "${tmp}" && makepkg -si --noconfirm >> "${LOG_FILE}" 2>&1); then
    rm -rf "${tmp}"
    fatal "Failed to build yay."
  fi
  rm -rf "${tmp}"
  AUR_HELPER="yay"
  msg "yay installed."
}

# ==========================
# PACKAGE INSTALLATION
# ==========================
install_packages() {
  local pac_list="${SCRIPT_DIR}/packages.txt"
  local aur_list="${SCRIPT_DIR}/packages-aur.txt"

  if [[ ! -f "${pac_list}" ]]; then
    fatal "packages.txt not found next to script (${SCRIPT_DIR})."
  fi

  info "Installing pacman packages (this can take a while)..."
  if ! sudo pacman -S --needed --noconfirm $(< "${pac_list}") >> "${LOG_FILE}" 2>&1; then
    fatal "pacman package installation failed. See ${LOG_FILE}"
  fi
  msg "pacman packages installed."

  if [[ -f "${aur_list}" ]] && [[ -s "${aur_list}" ]]; then
    info "Installing AUR packages via ${AUR_HELPER}..."
    if ! "${AUR_HELPER}" -S --needed --noconfirm $(< "${aur_list}") >> "${LOG_FILE}" 2>&1; then
      fatal "AUR package installation failed. See ${LOG_FILE}"
    fi
    msg "AUR packages installed."
  else
    info "No packages-aur.txt found — skipping AUR step."
  fi
}
