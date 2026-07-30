# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, hostName, ... }:

{
  imports =
    [ # Hardware-specific config is injected per-host by flake.nix, not
      # imported here - keeps this file identical across every machine.
      ./gaming.nix
      ./packages/fonts.nix
      ./packages/shell.nix
    ];

  # Bootloader.
  boot.loader.limine.enable = true;
  boot.loader.limine.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep 3 boot-menu entries per generation - matches the --keep 3 used by
  # `nh clean all` in the nixos-update script (packages/shell.nix) so the
  # Limine menu and the actual kept generations stay in sync.
  boot.loader.limine.maxGenerations = 3;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Extra selectable boot entry (Limine menu) for the Zen kernel, alongside
  # the default linuxPackages_latest above. cachyos isn't packaged in
  # nixpkgs, so it's not an option here the way it is on the Artix box.
  # (A third CachyOS-kernel specialisation was attempted via community
  # flakes - xddxdd/nix-cachyos-kernel, then Chaotic-Nyx - but both hit
  # binary-cache trust/timing issues that forced full source rebuilds of
  # rustc and other heavy packages. Reverted; revisit later with more
  # headroom.)
  specialisation.zen.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
  };

  # Derived from the hosts/<name>/ folder name (see flake.nix specialArgs) -
  # never hand-edit this, name the host directory instead.
  networking.hostName = hostName;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking via dhcpcd (plain DHCP client, no NetworkManager daemon)
  networking.useDHCP = true;


  programs.nix-ld.enable = true;


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
    extraGroups = [ "networkmanager" "wheel" "ydotool" "corectrl" "libvirtd" ];
    packages = with pkgs; [ ];
  };

  nix.settings.trusted-users=[ "fark" ] ;


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.labwc.enable = true;

  # GPU/CPU overclock + fan curve control panel. Requires membership in the
  # "corectrl" group (see users.users.fark.extraGroups above) to run without
  # a password prompt each time.
  programs.corectrl.enable = true;

  # VM testing (same workflow used to validate this whole config). Requires
  # membership in the "libvirtd" group (see users.users.fark.extraGroups).
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Auto-login straight into labwc via ly, no password prompt.
  # Fine for a personal/VM box; revisit for a shared machine.
  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "labwc";
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

  # zsh: home.nix stows .zshrc/.zshenv, but the shell itself still needs to
  # be installed and registered in /etc/shells.
  programs.zsh.enable = true;

  # AMD GPU: OpenGL/Vulkan (mesa's RADV, no separate vulkan-radeon package
  # needed on NixOS) plus 32-bit support for gaming/Proton.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  hardware.cpu.amd.updateMicrocode = true;
  # Games/Proton commonly need this raised past the kernel default;
  # Steam's own client warns about it if it's too low.
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  # Portals: screen sharing, file pickers, etc for Wayland apps. labwc's own
  # module sets a default backend preference but doesn't enable xdg.portal
  # or provide the wlr backend package itself - both still needed here.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    jj
    nh
    fastfetch
    git
    wayland
    emacs
    nano
    foot
    adwaita-icon-theme
    hicolor-icon-theme

    # Ported from the Artix pacman -Qe list (explicitly-installed packages).
    # Themes (phinger-cursors comes in via home.pointerCursor in home.nix)
    adw-gtk3
    
    # General utilities
    btop
    rsync
    gammastep
    wlrctl
    obs-studio
    android-tools
    ntfs3g
    alsa-utils
    vulkan-tools
    tixati
    config.boot.kernelPackages.cpupower
    # Dev tooling
    clang
    cmake
    lld
    llvm
    mold
    nasm
    go
    scdoc
    gcc
  ];
  


  environment.variables.NH_FLAKE = "/home/fark/.config/dots/nix";

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
