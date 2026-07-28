#!/usr/bin/env bash
# Bootstrap this flake config onto a freshly installed NixOS machine - run
# this once, right after the base install (e.g. Calamares) is done and
# you've rebooted into the bare system, with this repo already cloned to
# ~/.config/dots. Run as the normal user; it uses sudo itself where root
# is actually needed.
#
# Usage: nix/bootstrap.sh <hostname>
#   <hostname> names the hosts/<hostname>/ folder, which is also what
#   networking.hostName becomes (see flake.nix specialArgs / configuration.nix).

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <hostname>" >&2
  exit 1
fi
HOST="$1"

NIX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_DIR="$NIX_DIR/hosts/$HOST"

mkdir -p "$HOST_DIR"

if [ ! -f "$HOST_DIR/hardware-configuration.nix" ]; then
  echo "==> Generating hardware-configuration.nix for $HOST"
  sudo cp /etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware-configuration.nix"
  sudo chown "$USER": "$HOST_DIR/hardware-configuration.nix"
else
  echo "==> $HOST_DIR/hardware-configuration.nix already exists, leaving it alone"
fi

echo "==> Switching to flake config for host '$HOST'"
sudo nixos-rebuild switch --flake "path:$NIX_DIR#$HOST"

echo "==> Done. Reboot to confirm the Limine boot menu (latest/zen) looks right."
