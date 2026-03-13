{
  description = "NixOS Flake for Minecraft Servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { nixpkgs, nix-minecraft, agenix, ... }:
  let
    system = "x86_64-linux";

    # pkgs with the nix-minecraft overlay so pkgsMc.fabricServers.* is available
    pkgsMc = import nixpkgs {
          inherit system;
          overlays = [ nix-minecraft.overlay ];
          config.allowUnfree = true;
        };

  in {

    nixosConfigurations.decker = nixpkgs.lib.nixosSystem {
      inherit system;

      # Make pkgsMc available to modules
      specialArgs = { inherit pkgsMc; };

      modules = [
        ./configuration.nix
        ./server.nix
        ./backup.nix
        nix-minecraft.nixosModules.minecraft-servers
        agenix.nixosModules.default
      ];
    };
  };
}
