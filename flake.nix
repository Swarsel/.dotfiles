{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;

    # user-level configuration
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
	  };

    # overlay to access bleeding edge emacs
    emacs-overlay = {
      url = github:nix-community/emacs-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    # i use this mainly to not have to build all firefox extensions
    # myself as well as for the emacs-init package (tbd)
    nur.url = github:nix-community/NUR;

    # provides GL to non-NixOS hosts
    nixgl.url = github:guibou/nixGL;

    # manages all themeing using Home-Manager
    stylix.url = github:danth/stylix;

    # nix secrets management
    sops-nix.url = github:Mic92/sops-nix;

    # enable secure boot on NixOS
    lanzaboote.url = github:nix-community/lanzaboote;

  };

  outputs = inputs@{ self, nixpkgs, home-manager, emacs-overlay, nur, nixgl, stylix, sops-nix, lanzaboote, ... }: let
    system = "x86_64-linux"; # not very portable, but I do not use other architectures at the moment
    pkgs = import nixpkgs { inherit system;
                            overlays = [ emacs-overlay.overlay
                                         nur.overlay
                                         nixgl.overlay
                                       ];
                            config.allowUnfree = true;
                          };
    # NixOS modules that can only be used on NixOS systems
    nixModules = [ stylix.nixosModules.stylix
                   ./profiles/common/nixos.nix
                 ];

    # Home-Manager modules wanted on non-NixOS systems
    homeModules = [ stylix.homeManagerModules.stylix
                  ];
    # Home-Manager modules wanted on both NixOS and non-NixOS systems
    mixedModules = [ sops-nix.homeManagerModules.sops
                     ./profiles/common/home.nix
                   ];
  in {

    # NixOS setups - run home-manager as a NixOS module for better compatibility
    # another benefit - full rebuild on nixos-rebuild switch
    # run rebuild using `nswitch`

    # NEW HOSTS: For a new host, decide whether a NixOS (nixosConfigurations) or non-NixOS (homeConfigurations) is used.
    # Make sure to move hardware-configuration to the appropriate location, by default it is found in /etc/nixos/.

    nixosConfigurations = {

    	onett = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = nixModules ++ [
          ./profiles/onett/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.swarsel.imports = mixedModules ++ [
				      ./profiles/onett/home.nix
            ];
          }
        ];
		  };

      stand = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = nixModules ++ [
          ./profiles/stand/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.homelen.imports = mixedModules ++ [
				      ./profiles/stand/home.nix
            ];
          }
        ];
		  };

      threed = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = nixModules ++ [
          lanzaboote.nixosModules.lanzaboote
          ./profiles/threed/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.swarsel.imports = mixedModules ++ [
				      ./profiles/threed/home.nix
            ];
          }
        ];
		  };

	  };

    # pure Home Manager setups - for non-NixOS machines
    # run rebuild using `hmswitch`

	  homeConfigurations = {

		  "leons@PCisLee" = home-manager.lib.homeManagerConfiguration {
			  inherit pkgs;
			  modules = homeModules ++ mixedModules ++ [
				  ./profiles/surface/home.nix
			  ];
		  };

	  };

  };
}
