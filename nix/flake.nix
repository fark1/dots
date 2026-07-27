{
  description = "fark's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming: CachyOS kernel, Proton-GE, Proton-CachyOS, CachyOS-Settings port.
    # nix-cachyos-kernel intentionally does NOT follow our nixpkgs - its
    # "pinned" overlay is built against a specific nixpkgs revision for
    # guaranteed binary cache hits, so leave it on its own pin.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
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

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.fark = import ./home.nix;
        }
      ];
    };
  };
}
