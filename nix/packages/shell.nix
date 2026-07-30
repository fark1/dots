{ pkgs, ... }:

let
  # Bumps only the nixpkgs input (proton-ge/proton-cachyos/cachyos-settings
  # stay pinned) and switches. set -euo pipefail means a failed switch stops
  # the script before the cleanup step ever runs. nh already escalates
  # privileges itself, so no sudo here.
  nixos-update = pkgs.writeShellScriptBin "nixos-update" ''
    set -euo pipefail

    nh os switch --update-input nixpkgs /home/fark/.config/dots/nix

    # --keep 2 matches boot.loader.limine.maxGenerations so the boot menu
    # and generation cleanup stay in sync.
    nh clean all --keep 2
  '';
in
{
  environment.systemPackages = [
    nixos-update
  ];
}
