#!/usr/bin/env bash
# install-mode-switch.sh — one-time root setup for game-mode/media-mode.
#
# Installs a sudoers drop-in so the smr user can start/stop the local
# k3s server (and kill its containers) without a password prompt. That is
# the only root privilege the mode-switch scripts need.
#
# Usage: sudo ./scripts/install-mode-switch.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0"
    exit 1
fi

DROPIN=/etc/sudoers.d/k3s-mode-switch
cat > "$DROPIN" <<'EOF'
# Allow the desktop user to flip caliban between game mode and media mode
# (see scripts/game-mode.sh / media-mode.sh in home-kubernetes-cloud).
smr ALL=(root) NOPASSWD: /usr/bin/systemctl start k3s.service, /usr/bin/systemctl stop k3s.service, /usr/local/bin/k3s-killall.sh
EOF
chmod 0440 "$DROPIN"

visudo -c -f "$DROPIN" >/dev/null && echo "Installed $DROPIN"

# Desktop launchers for couch use.
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APPS_DIR=/home/smr/.local/share/applications
mkdir -p "$APPS_DIR"

cat > "$APPS_DIR/game-mode.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Game Mode
Comment=Spin down k3s + VMs, free the GPU for gaming
Exec=x-terminal-emulator -e bash -c "$REPO_DIR/scripts/game-mode.sh; read -p 'Done. Press enter to close.'"
Icon=input-gaming
Terminal=false
Categories=Game;System;
EOF

cat > "$APPS_DIR/media-mode.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Media Mode
Comment=Bring the k3s cluster and Plex stack back up
Exec=x-terminal-emulator -e bash -c "$REPO_DIR/scripts/media-mode.sh; read -p 'Done. Press enter to close.'"
Icon=multimedia-player
Terminal=false
Categories=AudioVideo;System;
EOF

chown smr:smr "$APPS_DIR/game-mode.desktop" "$APPS_DIR/media-mode.desktop"
echo "Installed Game Mode / Media Mode desktop launchers."
