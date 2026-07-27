# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.limine.enable = true;
  boot.loader.limine.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Extra selectable boot entry (Limine menu) for the Zen kernel, alongside
  # the default linuxPackages_latest above. cachyos isn't packaged in
  # nixpkgs, so it's not an option here the way it is on the Artix box.
  specialisation.zen.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking via dhcpcd (plain DHCP client, no NetworkManager daemon)
  networking.useDHCP = true;

  # Set your time zone.
  time.timeZone = "Europe/Skopje";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."fark" = {
    isNormalUser = true;
    description = "fark";
    extraGroups = [ "networkmanager" "wheel" "ydotool" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.labwc.enable = true;

  # Auto-login straight into labwc via ly, no password prompt.
  # Fine for a personal/VM box; revisit for a shared machine.
  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "labwc";
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "fark";

  # PipeWire audio, managed declaratively (the autostart script in
  # common/labwc/autostart skips its own manual pipewire launch when
  # it detects systemd, so this is the only place it's started here).
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ydotool: common/labwc/environment and common/zsh/.zshrc hardcode
  # YDOTOOL_SOCKET=/tmp/.ydotool_socket to match how Artix's OpenRC service
  # starts ydotoold, so force the same path here instead of the module's
  # default (/run/ydotoold/socket) - keeps common/ unchanged across OSes.
  programs.ydotool.enable = true;
  environment.variables.YDOTOOL_SOCKET = lib.mkForce "/tmp/.ydotool_socket";

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
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    fastfetch
    git
    wayland
    librewolf
    emacs
    nano
    foot
    adwaita-icon-theme
    hicolor-icon-theme
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
