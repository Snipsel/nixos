{
  description = "Snipsel's NixOS configuration";
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = { self, nixpkgs, impermanence, sops-nix, ... }@inputs: {
    nixosConfigurations.latte = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
	./latte/hardware-configuration.nix
        impermanence.nixosModules.impermanence
        ./common.nix
	./linode.nix
	./latte/configuration.nix
      ];
    };
  };
}
