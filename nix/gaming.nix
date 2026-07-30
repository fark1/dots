{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.cachyos-settings.nixosModules.default
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = [
      inputs.proton-ge.packages.${pkgs.system}.default
      inputs.proton-cachyos.packages.${pkgs.system}.default
    ];
  };

  # General performance tuning (zram, io scheduler, THP, wine/proton NT
  # sync support, etc). GPU-specific tuning left off by default -
  # amdgpuGcnCompat is only for old GCN 1.0/2.x cards, not enabled since
  # the actual GPU generation isn't confirmed yet.
  cachyos.settings.enable = true;

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    wine
    winetricks
    rpcs3
    pcsx2
    gamescope 
    
  ];
}
