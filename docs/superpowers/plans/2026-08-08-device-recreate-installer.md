# Device Recreation Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `install.sh` + package lists that recreate this device's full config on a fresh Arch/CachyOS machine.

**Architecture:** Single bash script fetched via curl (repo is bare, script can't be checked out first). It pre-flights the system, installs packages from two generated list files, deploys the bare dotfiles repo to `~/.cfg`, then installs assets (font, SDDM theme, wallpapers), GTK themes, and enables systemd user services. Modeled on the old `.dotfiles-sevens/install.sh` (same style) with patterns from Dotbot (idempotency, backup-before-overwrite) and the Atlassian bare-repo approach.

**Tech Stack:** bash 5 (Arch), pacman, yay/paru, git bare repo, systemctl --user.

**Repo conventions:** All repo adds must use `git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f` (`.cfg/info/exclude` contains `*`). `install.sh` must be added with `+x` mode.

---

### Task 1: Generate package list files

**Files:**
- Create: `packages.txt`
- Create: `packages-aur.txt`

- [ ] **Step 1: Generate the lists from this machine**

```bash
pacman -Qqe | grep -v '^linux-cachyos' > /home/gio/packages.txt
pacman -Qqm > /home/gio/packages-aur.txt
```

Note: `linux-cachyos*` kernel packages are excluded intentionally — the new device may differ; the base kernel is always installed on Arch systems. Verify:

```bash
wc -l /home/gio/packages.txt /home/gio/packages-aur.txt
```
Expected: ~290 and ~25 lines.

- [ ] **Step 2: Verify no hardware-specific surprises**

```bash
grep -E 'intel|amd|nvidia|firmware|ucode' /home/gio/packages.txt
```
Expected: `intel-ucode`, `intel-media-driver`, `vpl-gpu-rt`, `vulkan-intel` etc. remain (per user's choice in spec — harmless extras on other hardware).

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/packages.txt /home/gio/packages-aur.txt
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add full package lists: packages.txt, packages-aur.txt"
```

---

### Task 2: install.sh skeleton — header, config, logging, usage

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Write the file with header, config constants, color/log helpers**

```bash
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
```

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit skeleton**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh skeleton: config, logging, usage"
```

---

### Task 3: Pre-flight checks

**Files:**
- Modify: `install.sh` (append after usage function)

- [ ] **Step 1: Append pre-flight functions**

```bash
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
    if curl -s --connect-timeout 5 --max-time 10 "${ep}" >/dev/null 2>&1; then
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
  (
    while true; do sudo -v; sleep 50; done
  ) &
  SUDO_PID=$!
  msg "Sudo privileges verified (keep-alive started)."
}

cleanup_on_exit() {
  local code=$?
  if [[ -n "${SUDO_PID}" ]] && kill -0 "${SUDO_PID}" 2>/dev/null; then
    kill "${SUDO_PID}" 2>/dev/null || true
  fi
  if [[ ${code} -ne 0 ]]; then
    error "Script exited with code ${code}"
  fi
}
trap 'cleanup_on_exit' EXIT INT TERM
```

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh pre-flight checks"
```

---

### Task 4: Base tools + AUR helper

**Files:**
- Modify: `install.sh` (append)

- [ ] **Step 1: Append base-tools and AUR-helper functions**

```bash
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
  if command -v paru &>/dev/null; then
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
```

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh base tools and AUR helper logic"
```

---

### Task 5: Package installation

**Files:**
- Modify: `install.sh` (append)

- [ ] **Step 1: Append package-install functions**

```bash
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
```

Note: `$(< file)` word-splits into args; packages have no spaces so this is safe. `set -f` is NOT set so globs in package names (none here) would expand — acceptable.

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh package installation"
```

---

### Task 6: Dotfiles deploy (bare clone + conflict backup + checkout)

**Files:**
- Modify: `install.sh` (append)

- [ ] **Step 1: Append deploy function (Atlassian pattern + backup)**

```bash
# ==========================
# DOTFILES DEPLOY
# ==========================
deploy_dotfiles() {
  if [[ -d "${DOTDIR}" ]] && [[ -d "${DOTDIR}/.git" ]]; then
    msg "~/.cfg already exists — pulling latest..."
    if ! git --git-dir="${DOTDIR}" pull --rebase >> "${LOG_FILE}" 2>&1; then
      warn "Pull failed — continuing with existing checkout."
    fi
    return 0
  fi

  info "Cloning dotfiles as bare repo into ~/.cfg..."
  if ! git clone --bare "${REPO_URL}" "${DOTDIR}" >> "${LOG_FILE}" 2>&1; then
    fatal "Failed to clone ${REPO_URL}"
  fi

  local config_cmd=(git --git-dir="${DOTDIR}" --work-tree="${HOME}")
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
    done
    "${config_cmd[@]}" checkout >> "${LOG_FILE}" 2>&1 \
      || fatal "Checkout failed even after backing up conflicts."
    warn "Conflicting configs backed up to: ${BACKUP_DIR}"
  fi

  "${config_cmd[@]}" config status.showUntrackedFiles no
  msg "Dotfiles deployed. Use 'git --git-dir=\$HOME/.cfg --work-tree=\$HOME' to manage."
}
```

Note: the `grep -E '^\s+'` parses `git checkout`'s "error: The following untracked working tree files would be overwritten by checkout:\n\tfoo" output — same trick as the Atlassian tutorial.

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh dotfiles deploy with conflict backup"
```

---

### Task 7: Post-deploy assets — font, SDDM theme, wallpapers

**Files:**
- Modify: `install.sh` (append)

- [ ] **Step 1: Append asset-install functions**

```bash
# ==========================
# POST-DEPLOY ASSETS
# ==========================
install_miracode_font() {
  local src="${HOME}/.local/share/fonts/Miracode.ttf"
  if [[ ! -f "${src}" ]]; then
    warn "Miracode.ttf not found in repo checkout — skipping font."
    return 0
  fi
  mkdir -p "${FONTS_DIR}"
  cp "${src}" "${FONTS_DIR}/"
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
  sudo mkdir -p /usr/share/sddm/themes
  sudo cp -r "${src}" /usr/share/sddm/themes/
  if [[ ! -f /etc/sddm.conf.d/10-silentsddm.conf ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Theme]
Current=SilentSDDM" | sudo tee /etc/sddm.conf.d/10-silentsddm.conf >/dev/null
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
```

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh font, SDDM theme, wallpaper install"
```

---

### Task 8: GTK themes/icons (best effort) + systemd user services

**Files:**
- Modify: `install.sh` (append)

- [ ] **Step 1: Append theme and service functions**

```bash
# ==========================
# GTK THEMES & ICONS (best effort)
# ==========================
install_theme_from_git() {
  # $1 = repo URL, $2 = install command string (run in repo dir)
  local repo="$1"; shift
  local dir
  dir="$(mktemp -d)"
  info "Cloning ${repo##*/}..."
  if ! git clone --depth=1 "${repo}" "${dir}" >> "${LOG_FILE}" 2>&1; then
    rm -rf "${dir}"
    warn "Failed to clone ${repo} — skipping."
    return 1
  fi
  if ! (cd "${dir}" && bash -c "$*" >> "${LOG_FILE}" 2>&1); then
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
      "./install.sh --libadwaita --tweaks all rimless"
  fi

  if [[ -d "${HOME}/.themes/Osaka-Dark-Solarized" ]]; then
    msg "Osaka themes already present — skipping."
  else
    install_theme_from_git \
      "https://github.com/Fausto-Korpsvart/Osaka-GTK-Theme" \
      "cd themes && ./install.sh --libadwaita --tweaks solarized macos"
  fi

  if [[ -d "${HOME}/.themes/Rosepine-Dark-Moon" ]]; then
    msg "Rose Pine themes already present — skipping."
  else
    install_theme_from_git \
      "https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme" \
      "cd themes && ./install.sh --libadwaita --tweaks moon macos"
  fi

  if [[ ! -d "${HOME}/.icons/Colloid" ]]; then
    install_theme_from_git \
      "https://github.com/vinceliuice/Colloid-icon-theme" \
      "./install.sh -d ${HOME}/.icons --scheme all --bold"
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
```

- [ ] **Step 2: Syntax check**

Run: `bash -n /home/gio/install.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh themes, icons, systemd user services"
```

---

### Task 9: main(), argument parsing, summary, smoke test

**Files:**
- Modify: `install.sh` (append at end)

- [ ] **Step 1: Append main + arg parsing + summary**

```bash
# ==========================
# SUMMARY
# ==========================
print_header() {
  printf "${GREEN}${BOLD}"
  cat << "EOF"
════════════════════════════════════════════════════════
  DOTIFLES — Full device recreation installer
════════════════════════════════════════════════════════
EOF
  printf "${NC}\n"
  printf "Repo: ${BLUE}%s${NC}\n" "${REPO_URL}"
  printf "Log:  ${BLUE}%s${NC}\n" "${LOG_FILE}"
  printf "\n"
}

print_summary() {
  printf "\n${GREEN}${BOLD}INSTALLATION COMPLETE${NC}\n\n"
  for item in "${INSTALL_SUMMARY[@]}"; do
    printf "  ${GREEN}✓${NC} %s\n" "${item}"
  done
  printf "\n${BOLD}Next steps:${NC}\n"
  printf "  1. Log out and select Niri in SDDM\n"
  printf "  2. If Nord wallpapers missing: copy from old device manually\n"
  printf "  3. Apple-cursors: install from gnome-look.org if wanted\n"
  printf "\n"
}

main() {
  mkdir -p "${LOG_DIR}"

  print_header

  step "Pre-flight Checks"
  check_not_root
  check_arch_based
  check_sudo
  check_internet
  add_summary "Pre-flight checks passed"

  step "Base Tools"
  install_base_tools
  add_summary "Base tools installed"

  step "AUR Helper"
  choose_aur_helper
  add_summary "AUR helper: ${AUR_HELPER}"

  step "Packages"
  install_packages
  add_summary "All packages installed"

  step "Dotfiles Deploy"
  deploy_dotfiles
  add_summary "Dotfiles checked out to ${HOME}"

  step "Fonts, SDDM, Wallpapers"
  install_miracode_font
  install_sddm_theme
  install_wallpapers
  add_summary "Assets installed (font, SDDM, wallpapers)"

  step "GTK Themes & Icons"
  install_gtk_themes
  add_summary "GTK themes/icons processed"

  step "Systemd User Services"
  enable_user_services
  add_summary "User services enabled"

  step "Finalize"
  print_summary
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      *) error "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

parse_arguments "$@"
main
```

- [ ] **Step 2: Syntax check + smoke test**

```bash
bash -n /home/gio/install.sh
bash /home/gio/install.sh --help
chmod +x /home/gio/install.sh
```
Expected: `--help` prints usage, exits 0.

- [ ] **Step 3: shellcheck (if installed)**

```bash
command -v shellcheck >/dev/null && shellcheck /home/gio/install.sh || echo "shellcheck not installed"
```
Fix any findings that are real bugs (not style). Rerun `bash -n`.

- [ ] **Step 4: Commit final**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio add -f /home/gio/install.sh
git --git-dir=/home/gio/.cfg --work-tree=/home/gio commit -m "Add install.sh main flow, summary, arg parsing"
```

---

### Task 10: Full verification & docs

**Files:**
- Modify: `docs/superpowers/plans/` (this plan, marked done)

- [ ] **Step 1: End-to-end dry review of the final script**

```bash
cat /home/gio/install.sh
```
Manually verify: every function called in `main()` exists; `TOTAL_STEPS=9` matches the 9 `step()` calls; `REPO_URL` matches `git --git-dir=/home/gio/.cfg remote get-url origin` (should be `https://github.com/giocld/dotifles`).

- [ ] **Step 2: Verify the git status is clean**

```bash
git --git-dir=/home/gio/.cfg --work-tree=/home/gio status --short
```
Expected: empty (nothing uncommitted).

- [ ] **Step 3: Record result**

Commit any plan-status updates. Report to user: script location, bootstrap command, what it covers, what's manual (f1-rosberg, Apple-cursors).

---

## Self-Review Notes

- Spec coverage: packages (T1), bootstrap/deploy (T6), font/SDDM/wallpapers (T7), themes (T8), services (T8), pre-flight (T3), base tools/AUR (T4), summary (T9) — all spec sections mapped.
- Placeholders: none — every step has exact code or commands.
- Type consistency: `AUR_HELPER` set in `choose_aur_helper`, used in `install_packages`; `BACKUP_DIR`, `WALLPAPERS_DIR`, `FONTS_DIR` all `readonly` at top; `install_theme_from_git` signature `(repo, cmd)` used consistently with quoted `"$*"` for the command string.
- Known risk: `install_theme_from_git` uses `bash -c "$*"` — requires commands to be written as one string with `cd` chained; verified pattern in Task 8 code.
