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
  - CachyOS (the package list includes CachyOS-only packages)
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
    fatal "pacman not found — this script requires CachyOS (or Arch with CachyOS repos)."
  fi
  if [[ -f /etc/os-release ]] && grep -q '^ID=cachyos$' /etc/os-release; then
    msg "CachyOS detected."
  else
    fatal "This script requires CachyOS — the package list includes CachyOS-only packages."
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

  info "Syncing package database..."
  sudo pacman -Sy --noconfirm >> "${LOG_FILE}" 2>&1 || fatal "Failed to sync package database."

  info "Installing pacman packages (this can take a while)..."
  if ! sudo pacman -S --noprogressbar --needed --noconfirm $(< "${pac_list}") 2>&1 | tee -a "${LOG_FILE}"; then
    fatal "pacman package installation failed. See ${LOG_FILE}"
  fi
  msg "pacman packages installed."

  if [[ -f "${aur_list}" ]] && [[ -s "${aur_list}" ]]; then
    if [[ -z "${AUR_HELPER}" ]]; then
      fatal "AUR helper not set — ordering bug."
    fi
    info "Installing AUR packages via ${AUR_HELPER}..."
    if ! "${AUR_HELPER}" -S --needed --noconfirm $(< "${aur_list}") 2>&1 | tee -a "${LOG_FILE}"; then
      fatal "AUR package installation failed. See ${LOG_FILE}"
    fi
    msg "AUR packages installed."
  else
    info "No packages-aur.txt found — skipping AUR step."
  fi
}

# ==========================
# DOTFILES DEPLOY
# ==========================
deploy_dotfiles() {
  local config_cmd=(git --git-dir="${DOTDIR}" --work-tree="${HOME}")
  if [[ -d "${DOTDIR}" ]] && git --git-dir="${DOTDIR}" rev-parse --git-dir &>/dev/null; then
    msg "~/.cfg already exists — pulling latest..."
    "${config_cmd[@]}" config status.showUntrackedFiles no || warn "Could not set status.showUntrackedFiles."
    if ! git --git-dir="${DOTDIR}" --work-tree="${HOME}" pull --rebase >> "${LOG_FILE}" 2>&1; then
      warn "Pull failed — continuing with existing checkout."
    fi
    return 0
  fi

  info "Cloning dotfiles as bare repo into ~/.cfg..."
  if ! git clone --bare "${REPO_URL}" "${DOTDIR}" >> "${LOG_FILE}" 2>&1; then
    warn "~/.cfg exists but is not a valid git repo — remove it to re-clone."
    fatal "Failed to clone ${REPO_URL}"
  fi

  info "Checking out into ${HOME}..."
  if ! "${config_cmd[@]}" checkout; then
    info "Some files conflict with existing configs — backing them up."
    mkdir -p "${BACKUP_DIR}"
    "${config_cmd[@]}" checkout 2>&1 | grep -E '^\s+' | sed 's/^\s*//' | while read -r f; do
      if [[ -e "${HOME}/${f}" ]] && [[ ! -e "${BACKUP_DIR}/${f}" ]]; then
        mkdir -p "$(dirname "${BACKUP_DIR}/${f}")"
        mv "${HOME}/${f}" "${BACKUP_DIR}/${f}"
        info "Backed up: ${f}"
      fi
    done || true
    "${config_cmd[@]}" checkout >> "${LOG_FILE}" 2>&1 \
      || fatal "Checkout failed after conflict handling. See ${LOG_FILE}"
    warn "Conflicting configs backed up to: ${BACKUP_DIR}"
  fi

  "${config_cmd[@]}" config status.showUntrackedFiles no
  msg "Dotfiles deployed. Use 'git --git-dir=\$HOME/.cfg --work-tree=\$HOME' to manage."
}

# ==========================
# POST-DEPLOY ASSETS
# ==========================
install_miracode_font() {
  local src="${HOME}/.local/share/fonts/Miracode.ttf"
  if [[ ! -f "${src}" ]]; then
    warn "Miracode.ttf not found in repo checkout — skipping font."
    return 0
  fi
  fc-cache -f >/dev/null 2>&1 || true
  msg "Miracode font installed."
}

install_sddm_theme() {
  local src="${HOME}/.config/sddm/SilentSDDM"
  if [[ ! -d "${src}" ]]; then
    warn "SilentSDDM theme not in repo checkout — skipping."
    return 0
  fi
  info "Installing SilentSDDM theme (needs sudo)..."
  sudo mkdir -p /usr/share/sddm/themes || { warn "Cannot create /usr/share/sddm/themes — skipping SDDM theme."; return 0; }
  sudo cp -r "${src}" /usr/share/sddm/themes/ || { warn "Failed to copy SilentSDDM theme — skipping."; return 0; }
  sudo rm -rf /usr/share/sddm/themes/SilentSDDM/docs \
    /usr/share/sddm/themes/SilentSDDM/nix \
    /usr/share/sddm/themes/SilentSDDM/flake.nix \
    /usr/share/sddm/themes/SilentSDDM/flake.lock \
    /usr/share/sddm/themes/SilentSDDM/default.nix \
    /usr/share/sddm/themes/SilentSDDM/install.sh \
    /usr/share/sddm/themes/SilentSDDM/test.sh \
    /usr/share/sddm/themes/SilentSDDM/change_avatar.sh \
    /usr/share/sddm/themes/SilentSDDM/README.md \
    /usr/share/sddm/themes/SilentSDDM/LICENSE 2>/dev/null || true
  if [[ ! -f /etc/sddm.conf.d/10-silentsddm.conf ]]; then
    sudo mkdir -p /etc/sddm.conf.d || true
    echo "[Theme]
Current=SilentSDDM" | sudo tee /etc/sddm.conf.d/10-silentsddm.conf >/dev/null || warn "Could not write SDDM theme config — set Current=SilentSDDM manually."
  fi
  msg "SilentSDDM theme installed and set as default."
}

install_wallpapers() {
  mkdir -p "${WALLPAPERS_DIR}"
  local count=0
  for img in "${HOME}"/.config/wallpapers/*; do
    if [[ -f "${img}" ]]; then
      cp "${img}" "${WALLPAPERS_DIR}/"
      ((++count)) || true
    fi
  done
  if [[ ${count} -gt 0 ]]; then
    msg "Copied ${count} wallpaper(s) to ${WALLPAPERS_DIR}."
  else
    warn "No wallpapers found in repo — skipping."
  fi

  if command -v awww &>/dev/null && [[ -f "${WALLPAPERS_DIR}/fireplace.gif" ]]; then
    info "Applying fireplace.gif via awww..."
    awww img "${WALLPAPERS_DIR}/fireplace.gif" -t none || warn "awww apply failed — apply manually."
  fi

  if [[ ! -d "${WALLPAPERS_DIR}/Nord" ]]; then
    warn "Nord wallpapers (f1-rosberg.jpg) are NOT in the repo — copy them manually from the old device."
  fi
}

# ==========================
# GTK THEMES & ICONS (best effort)
# ==========================
install_theme_from_git() {
  # $1 = repo URL, $2 = install command string (run in repo dir)
  local repo="$1"
  local cmd="$2"
  local dir
  dir="$(mktemp -d)"
  info "Cloning ${repo##*/}..."
  if ! git clone --depth=1 "${repo}" "${dir}" >> "${LOG_FILE}" 2>&1; then
    rm -rf "${dir}"
    warn "Failed to clone ${repo} — skipping."
    return 1
  fi
  if ! (cd "${dir}" && bash -c "${cmd}" >> "${LOG_FILE}" 2>&1); then
    rm -rf "${dir}"
    warn "Theme install failed for ${repo} — skipping."
    return 1
  fi
  rm -rf "${dir}"
  msg "Installed theme: ${repo##*/}"
  return 0
}

install_gtk_themes() {
  if [[ -d "${HOME}/.themes/Colloid" ]]; then
    msg "Colloid GTK themes already present — skipping."
  else
    install_theme_from_git \
      "https://github.com/vinceliuice/Colloid-gtk-theme" \
      "./install.sh --libadwaita --tweaks all rimless" \
      || true
    install_theme_from_git \
      "https://github.com/vinceliuice/Colloid-gtk-theme" \
      "./install.sh --libadwaita --theme grey --tweaks black rimless" \
      || true
  fi

  if [[ -d "${HOME}/.themes/Osaka-Dark-Solarized" ]]; then
    msg "Osaka themes already present — skipping."
  else
    install_theme_from_git \
      "https://github.com/Fausto-Korpsvart/Osaka-GTK-Theme" \
      "cd themes && ./install.sh --libadwaita --tweaks solarized macos" \
      || true
  fi

  if [[ -d "${HOME}/.themes/Rosepine-Dark-Moon" ]]; then
    msg "Rose Pine themes already present — skipping."
  else
    install_theme_from_git \
      "https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme" \
      "cd themes && ./install.sh --libadwaita --tweaks moon macos" \
      || true
  fi

  if [[ ! -d "${HOME}/.icons/Colloid" ]]; then
    install_theme_from_git \
      "https://github.com/vinceliuice/Colloid-icon-theme" \
      "./install.sh -d \"${HOME}/.icons\" --scheme all --bold" \
      || true
  else
    msg "Colloid icon theme already present — skipping."
  fi

  if [[ ! -d "${HOME}/.icons/Apple-cursors" ]]; then
    warn "Apple-cursors is not in a repo (gnome-look download). Install manually from gnome-look.org."
  fi
}

# ==========================
# SYSTEMD USER SERVICES
# ==========================
enable_user_services() {
  local wants="${HOME}/.config/systemd/user/graphical-session.target.wants"
  if [[ ! -d "${wants}" ]]; then
    info "No graphical-session.wants dir — skipping service enable."
    return 0
  fi
  systemctl --user daemon-reload >> "${LOG_FILE}" 2>&1 || true
  for unit in "${wants}"/*; do
    local name
    name="$(basename "${unit}")"
    info "Enabling user service: ${name}"
    systemctl --user enable "${name}" >> "${LOG_FILE}" 2>&1 || warn "Could not enable ${name}"
  done
  msg "User services enabled."
}
