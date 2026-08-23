#!/usr/bin/env bash
# Copy the (read-only) Nix store Spotify install to ~/.local/share/spotify
# so spicetify can patch it, then apply the patch.
set -euo pipefail

BIN=$(readlink -f "$(command -v spotify)")
SRC=$(dirname "$BIN")
DEST="$HOME/.local/share/spotify"

if [ ! -d "$SRC" ]; then
    echo "Could not find Spotify install at $SRC (resolved from $BIN)" >&2
    exit 1
fi

mkdir -p "$DEST"
rm -rf "${DEST:?}/"*
cp -aL "$SRC/." "$DEST/"
chmod -R u+w "$DEST"

# The nixpkgs launcher wrapper execs the store binary; point it at the local
# copy so the spicetify-patched app is what actually runs.
sed -i 's|exec -a "\$0" "/nix/store/[^"]*/share/spotify/.spotify-wrapped"|exec -a "$0" "$(dirname "$0")/.spotify-wrapped"|' "$DEST/spotify"

mkdir -p "$HOME/.config/spotify"
touch "$HOME/.config/spotify/prefs"

spicetify config spotify_path "$DEST"
spicetify config prefs_path "$HOME/.config/spotify/prefs"
spicetify backup apply
spicetify apply

echo "Done. Launch Spotify with: $DEST/spotify"
