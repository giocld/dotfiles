# Device Recreation Installer — Design Spec

Date: 2026-08-08
Status: Approved (user: "yea")

## Goal

Recreate this device's full configuration on a new Arch/CachyOS machine from the
`giocld/dotifles` bare-repo dotfiles repository, with a single `install.sh`.

## Repository Layout (3 new files, force-added to repo)

- `install.sh` — main installer (bash, modeled on the old `.dotfiles-sevens/install.sh` style)
- `packages.txt` — full explicit pacman package list (from `pacman -Qqe`, ~300 pkgs)
- `packages-aur.txt` — full explicit AUR/foreign package list (from `pacman -Qqm`, ~25 pkgs)

## Bootstrap

Repo is a bare dotfiles repo (`git --git-dir=$HOME/.cfg --work-tree=$HOME`), so the
script cannot be checked out before it is needed. Fetch it directly:

```
curl -fsSL https://raw.githubusercontent.com/giocld/dotifles/main/install.sh -o /tmp/install.sh
bash /tmp/install.sh
```

The script clones the repo itself using the origin URL (hardcoded, matches `~/.cfg` remote).

## Steps

1. **Pre-flight**: refuse root, verify Arch-based distro, check internet, sudo keep-alive loop.
2. **Base tools**: install git, base-devel, curl, jq via pacman.
3. **AUR helper**: use yay if present; otherwise install yay (pacman repo first, else build from AUR).
4. **Packages**: `pacman -S --needed --noconfirm $(< packages.txt)`, then
   `$AUR_HELPER -S --needed --noconfirm $(< packages-aur.txt)`.
5. **Dotfiles deploy**: bare-clone to `~/.cfg`; checkout to `$HOME` with
   `status.showUntrackedFiles no`; any conflicting paths moved to
   `~/.config_backup_<timestamp>` before checkout.
6. **Post-deploy assets** (all sourced from the repo tree):
   - Miracode font → `~/.local/share/fonts/` + `fc-cache -f`
   - SilentSDDM theme → `~/.local/share/sddm/themes/`
   - Wallpapers (`fireplace.gif`, `current.jpg`) → `~/Pictures/Wallpapers/`
   - Apply via `awww`: `fireplace.gif` to all outputs
   - Note: `f1-rosberg.jpg` is NOT in the repo (user choice) — must be copied manually
     from this device; script prints a reminder if the Nord wallpaper dir is missing
7. **GTK themes/icons** (not in repo — ~1.1GB on disk): best-effort clone+install
   - Colloid-gtk-theme (all variants currently installed: Colloid, Colloid-Dark, Nord, Dracula, Gruvbox, Catppuccin, Everforest, Grey)
   - Osaka-GTK-Theme (Solarized)
   - Rose-Pine-GTK-Theme (Moon)
   - Colloid-icon-theme (scheme all)
   - Apple-cursors (icon/cursor pack)
8. **Systemd user services**: enable units found in `.config/systemd/user/*.wants/`.
9. **Summary** + next steps (logout, select niri in SDDM).

## Explicit Non-Goals

- No Nix flake conversion (separate future decision).
- No package removal/uninstall of pre-existing packages on target.
- No browser profiles / private data (they stay out of the repo).
- Hardware-specific packages (intel-ucode, vulkan-intel, linux-cachyos headers) are
  included in `packages.txt` per user choice; script does not filter them.

## Error Handling

- `set -Eeuo pipefail`, `trap ERR` cleanup with log file in `~/.cache/`.
- Backup dir preserved on failure; script prints restore instructions.
- Optional steps (themes, wallpapers) degrade to warnings, not fatal errors.
