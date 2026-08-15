{
  description = "My NixOS + Home Manager configuration(s)";

  inputs = {
    # Unstable tracks recent Hyprland releases closely. Switch to a
    # release branch (e.g. nixos-25.05) later if you want more stability.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community-maintained quirks/fixes for specific laptop models.
    # Optional — see README for how to find & use your model's module.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      # Add more entries here later for future machines, e.g.
      #   nixosConfigurations.desktop = nixpkgs.lib.nixosSystem { ... };
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            # CHANGE "changeme" to your actual username
            home-manager.users.harshvse= import ./home/home.nix;
          }
        ];
      };
    };
}
