{ config, pkgs, lib, ... }:

{
  home.username = "fark";
  home.homeDirectory = "/home/fark";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    quickshell
    alacritty
    mpv
    thunar
    stow
    swaybg
    foot
    fuzzel
    grim
    slurp
    pulseaudio
    pavucontrol
    wlr-randr
  ];

  # Applies common/ from the dotfiles repo via stow on every activation.
  # Assumes the repo is cloned to ~/.config/dots (same path on every machine).
  # zsh targets $HOME directly since that's where .zshrc/.zshenv are read from;
  # everything else targets $HOME/.config to match how each app already expects
  # its config to be laid out.
  home.activation.stowDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DOTS="$HOME/.config/dots/common"
    if [ -d "$DOTS" ]; then
      ${pkgs.stow}/bin/stow -d "$DOTS" -t "$HOME/.config" --restow \
        foot alacritty Thunar labwc mpv quickshell
      ${pkgs.stow}/bin/stow -d "$DOTS" -t "$HOME" --restow zsh
      mkdir -p "$HOME/.local/share/themes"
      ${pkgs.stow}/bin/stow -d "$DOTS" -t "$HOME/.local/share/themes" --restow themes
    fi
  '';

  programs.home-manager.enable = true;
}
