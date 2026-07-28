#!/usr/bin/env bash
# Bootstrap this flake config onto a freshly installed NixOS machine - run
# this once, right after the base install (e.g. Calamares) is done and
# you've rebooted into the bare system, with this repo already cloned to
# ~/.config/dots. Run as the normal user; it uses sudo itself where root
# is actually needed.
#
# Usage: nix/bootstrap.sh [hostname]
#   Prompts for a hostname if not given as an argument. It names the
#   hosts/<hostname>/ folder, which is also what networking.hostName
#   becomes (see flake.nix specialArgs / configuration.nix).

set -euo pipefail

HOST="${1:-}"
if [ -z "$HOST" ]; then
  read -rp "Hostname for this machine: " HOST
fi
if ! [[ "$HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
  echo "invalid hostname '$HOST' - letters, digits, hyphens only, can't start with a hyphen" >&2
  exit 1
fi

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
