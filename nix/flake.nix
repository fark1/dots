{
  description = "fark's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming: CachyOS kernel (via Chaotic-Nyx), Proton-GE, Proton-CachyOS,
    # CachyOS-Settings port. chaotic intentionally does NOT follow our
    # nixpkgs - its kernel binaries are built against a specific nixpkgs
    # revision for guaranteed binary cache hits, so leave it on its own pin.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    proton-ge = {
      url = "github:Daaboulex/proton-ge-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    proton-cachyos = {
      url = "github:Daaboulex/proton-cachyos-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cachyos-settings = {
      url = "github:Daaboulex/cachyos-settings-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      hostsDir = ./hosts;

      # Every subdirectory of hosts/ becomes a nixosConfigurations entry
      # named after it, as long as it has a hardware-configuration.nix.
      # Adding a new machine is just: nixos-generate-config, drop the
      # result in hosts/<name>/hardware-configuration.nix, nothing to
      # edit here.
      hostNames = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir hostsDir)
      );

      mkHost = name: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          (hostsDir + "/${name}/hardware-configuration.nix")
          inputs.chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.fark = import ./home.nix;
          }
        ];
      };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs hostNames mkHost;
    };
}
