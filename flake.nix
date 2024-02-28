{
  description = "Snipsel's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = { self, nixpkgs, impermanence, ... }@inputs: {
    nixosConfigurations.latte = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        impermanence.nixosModules.impermanence
	./hardware-configuration.nix
	./linode.nix
        ./common.nix
      ];
    };
  };
}
