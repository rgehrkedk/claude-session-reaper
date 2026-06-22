#!/usr/bin/env bash
# install.sh — symlink claude-reaper onto your PATH. Optionally set up the scheduler.
#
#   ./install.sh                 # symlink to ~/.local/bin, then print next steps
#   ./install.sh --schedule      # also run `claude-reaper install` (launchd/systemd)
#   PREFIX=/usr/local ./install.sh   # symlink to $PREFIX/bin instead
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/claude-reaper"
BIN="${PREFIX:-$HOME/.local}/bin"
DEST="$BIN/claude-reaper"

chmod +x "$SRC"
mkdir -p "$BIN"
ln -sf "$SRC" "$DEST"
echo "Linked $DEST → $SRC"

case ":$PATH:" in
    *":$BIN:"*) : ;;
    *) echo "NOTE: $BIN is not on your PATH. Add it:  export PATH=\"$BIN:\$PATH\"" ;;
esac

if [ "${1:-}" = "--schedule" ]; then
    "$DEST" install
else
    echo
    echo "Next:"
    echo "  claude-reaper                 # see what's parked (read-only)"
    echo "  claude-reaper config --init   # write a config to tweak"
    echo "  claude-reaper install         # run it automatically (launchd/systemd)"
fi
