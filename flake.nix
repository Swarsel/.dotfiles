{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  inputs = {
    
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    
    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-24.05;
    
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
    
    # manages all theming using Home-Manager
    stylix.url = github:danth/stylix;
    
    # nix secrets management
    sops-nix.url = github:Mic92/sops-nix;
    
    # enable secure boot on NixOS
    lanzaboote.url = github:nix-community/lanzaboote;
    
    # nix for android
    nix-on-droid = {
      url = github:t184256/nix-on-droid/release-23.05;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # generate NixOS images
    nixos-generators = {
      url = github:nix-community/nixos-generators;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # patches for gaming on nix
    nix-gaming = {
      url = github:fufexan/nix-gaming;
    };
    
    # hardware quirks on nix
    nixos-hardware = {
      url = github:NixOS/nixos-hardware/master;
    };
    
    # dynamic library loading
    nix-alien = {
      url = github:thiagokokada/nix-alien;
    };
    
  };

  outputs = inputs@{
    self,
      
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      nix-on-droid,
      nixos-generators,
      emacs-overlay,
      nur,
      nixgl,
      stylix,
      sops-nix,
      lanzaboote,
      nix-gaming,
      nixos-hardware,
      nix-alien,
      
      ...
  }: let
    
    system = "x86_64-linux"; # not very portable, but I do not use other architectures at the moment
    pkgs = import nixpkgs { inherit system;
                            overlays = [ emacs-overlay.overlay
                                         nur.overlay
                                         nixgl.overlay
                                         (final: _prev: {
                                           stable = import nixpkgs-stable {
                                             inherit (final) system config;
                                           };
                                         })
                                       ];
                            config.allowUnfree = true;
                          };
    
    # for ovm arm hosts
    armpkgs = import nixpkgs { system = "aarch64-linux";
                            overlays = [ emacs-overlay.overlay
                                         nur.overlay
                                         nixgl.overlay
                                       ];
                            config.allowUnfree = true;
                          };
    
    
    # NixOS modules that can only be used on NixOS systems
    nixModules = [ stylix.nixosModules.stylix
                   sops-nix.nixosModules.sops
                   ./profiles/common/nixos.nix
                   # dynamic library loading
                   ({ self, system, ... }: {
                     environment.systemPackages = with self.inputs.nix-alien.packages.${system}; [
                       nix-alien
                     ];
                     # needed for `nix-alien-ld`
                     programs.nix-ld.enable = true;
                     })
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
      
      sandbox = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/sandbox/nixos.nix
        ];
      };
      
      twoson = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = nixModules ++ [
          ./profiles/twoson/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.swarsel.imports = mixedModules ++ [
              ./profiles/twoson/home.nix
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
      
      fourside = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = nixModules ++ [
          nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
          ./profiles/fourside/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.swarsel.imports = mixedModules ++ [
              ./profiles/fourside/home.nix
            ];
          }
        ];
      };
      
      winters = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = nixModules ++ [
          nixos-hardware.nixosModules.framework-16-inch-7040-amd
          ./profiles/winters/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.swarsel.imports = mixedModules ++ [
              ./profiles/winters/home.nix
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
      
      nginx = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/nginx/nixos.nix
        ];
      };
      
      calibre = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/calibre/nixos.nix
        ];
      };
      
      jellyfin = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          # sops-nix.nixosModules.sops
          ./profiles/server1/jellyfin/nixos.nix
        ];
      };
      
      transmission = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/transmission/nixos.nix
        ];
      };
      
      matrix = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        # this is to import a service module that is not on nixpkgs
        # this way avoids infinite recursion errors
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/matrix/nixos.nix
        ];
      };
      
      sound = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/sound/nixos.nix
        ];
      };
      
      spotifyd = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/spotifyd/nixos.nix
        ];
      };
      
      paperless = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/server1/paperless/nixos.nix
        ];
      };
      
      #ovm swarsel
      sync = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/remote/oracle/sync/nixos.nix
        ];
      };
      
      #ovm swarsel
      swatrix = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs pkgs; };
        modules = [
          sops-nix.nixosModules.sops
          ./profiles/remote/oracle/matrix/nixos.nix
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

    nixOnDroidConfigurations = {
      
      default = nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [
          ./profiles/mysticant/configuration.nix
        ];
      };
      
    };

    packages.x86_64-linux = {
      
    };

  };
}
