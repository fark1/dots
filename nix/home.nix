{ config, pkgs, lib, ... }:

{
  imports = [
    ./browser.nix
  ];

  home.username = "fark";
  home.homeDirectory = "/home/fark";
  home.stateVersion = "26.05";

  # Cursor theme for every app - labwc's own environment file (common/labwc)
  # already sets XCURSOR_THEME/XCURSOR_SIZE for Wayland/XWayland clients;
  # this covers GTK apps' internal cursor-theme setting plus the
  # ~/.icons/default symlink some non-Wayland-aware tools still look for.
  home.pointerCursor = {
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.packages = with pkgs; [
    quickshell
    mpv
    thunar
    stow
    swaybg
    foot
    fuzzel
    grim
    slurp
    wl-clipboard
    pulseaudio
    pavucontrol
    wlr-randr
    vscode
    vesktop
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
