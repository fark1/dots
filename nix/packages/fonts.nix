{ pkgs, ... }:

{
  # Fonts ported from the Artix machine's pacman/manual font install.
  # Fairfax Hax isn't here - it's not packaged in nixpkgs at all (see
  # earlier investigation), only used by common/foot and common/alacritty
  # for now.
  fonts.packages = with pkgs; [
    adwaita-fonts
    freefont_ttf
    noto-fonts
    noto-fonts-color-emoji
    dejavu_fonts
    font-awesome
    nerd-fonts.jetbrains-mono
    liberation_ttf
    roboto-mono
    symbola
    ubuntu-classic
    fairfax-hd
    scientifica
    fairfax
    miracode
  ];
}
