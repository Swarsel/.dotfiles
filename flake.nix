{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    systems.url = "github:nix-systems/default-linux";

    # user-level configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # overlay to access bleeding edge emacs
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    # i use this mainly to not have to build all firefox extensions
    # myself as well as for the emacs-init package (tbd)
    nur.url = "github:nix-community/NUR";

    # provides GL to non-NixOS hosts
    nixgl.url = "github:guibou/nixGL";

    # manages all theming using Home-Manager
    stylix.url = "github:danth/stylix";

    # nix secrets management
    sops-nix.url = "github:Mic92/sops-nix";

    # enable secure boot on NixOS
    lanzaboote.url = "github:nix-community/lanzaboote";

    # nix for android
    nix-on-droid = {
      url = "github:t184256/nix-on-droid/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # generate NixOS images
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hardware quirks on nix
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    # dynamic library loading
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
    };

    # automatic nintendo switch payload injection
    nswitch-rcm-nix = {
      url = "github:Swarsel/nswitch-rcm-nix";
    };

    # weekly updated nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , home-manager
    , systems
    , ...
    }:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;

      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );

      # pkgs for home-manager builds
      # homepkgs = import nixpkgs { system = "x86_64-linux";
      #                             overlays = [ inputs.emacs-overlay.overlay
      #                                          inputs.nur.overlay
      #                                          inputs.nixgl.overlay
      #                                          (final: _prev: {
      #                                            stable = import inputs.nixpkgs-stable {
      #                                              inherit (final) system config;
      #                                            };
      #                                          })
      #                                        ];
      #                             config.allowUnfree = true;
      #                           };

      # # NixOS modules that ca
      n only be used on NixOS systems
      nixModules = [
        inputs.stylix.nixosModules.stylix
        inputs.sops-nix.nixosModules.sops
        inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
        ./profiles/common/nixos
      ];

      # Home-Manager modules wanted on non-NixOS systems
      homeModules = [
        inputs.stylix.homeManagerModules.stylix
      ];

      # Home-Manager modules wanted on both NixOS and non-NixOS systems
      mixedModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.nix-index-database.hmModules.nix-index
        ./profiles/common/home
      ];

    in
    {

      inherit lib;
      inherit mixedModules;
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home;

      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells = forEachSystem
        (pkgs:
          {
            default = pkgs.mkShell {
              # Enable experimental features without having to specify the argument
              NIX_CONFIG = "experimental-features = nix-command flakes";
              nativeBuildInputs = [ pkgs.nix pkgs.home-manager pkgs.git ];
            };
          });
      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
      overlays = [
        (import ./overlays { inherit inputs; }).additions
        (import ./overlays { inherit inputs; }).modifications
        (import ./overlays { inherit inputs; }).nixpkgs-stable
        inputs.nur.overlay
        inputs.emacs-overlay.overlay
        inputs.nixgl.overlay
      ];



      # NixOS setups - run home-manager as a NixOS module for better compatibility
      # another benefit - full rebuild on nixos-rebuild switch
      # run rebuild using `nswitch`

      # NEW HOSTS: For a new host, decide whether a NixOS (nixosConfigurations) or non-NixOS (homeConfigurations) is used.
      # Make sure to move hardware-configuration to the appropriate location, by default it is found in /etc/nixos/.

      nixosConfigurations = {


        sandbox = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.disko.nixosModules.disko
            ./profiles/sandbox/disk-config.nix
            inputs.sops-nix.nixosModules.sops
            ./profiles/sandbox/nixos.nix
          ];
        };

        threed = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = nixModules ++ [
            inputs.lanzaboote.nixosModules.lanzaboote
            ./profiles/threed/nixos.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.users.swarsel.imports = mixedModules ++ [
                ./profiles/threed/home.nix
              ];
            }
          ];
        };

        fourside = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = nixModules ++ [
            ./profiles/fourside
          ];
        };

        winters = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = nixModules ++ [
            inputs.nixos-hardware.nixosModules.framework-16-inch-7040-amd
            ./profiles/winters/nixos.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.users.swarsel.imports = mixedModules ++ [
                ./profiles/winters/home.nix
              ];
            }
          ];
        };

        nginx = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/nginx/nixos.nix
          ];
        };

        calibre = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/calibre/nixos.nix
          ];
        };

        jellyfin = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./profiles/server1/jellyfin/nixos.nix
          ];
        };

        transmission = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/transmission/nixos.nix
          ];
        };

        matrix = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/matrix/nixos.nix
          ];
        };

        sound = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/sound/nixos.nix
          ];
        };

        spotifyd = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/spotifyd/nixos.nix
          ];
        };

        paperless = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/server1/paperless/nixos.nix
          ];
        };

        #ovm swarsel
        sync = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/remote/oracle/sync/nixos.nix
          ];
        };

        #ovm swarsel
        swatrix = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./profiles/remote/oracle/matrix/nixos.nix
          ];
        };
      };

      # pure Home Manager setups - for non-NixOS machines
      # run rebuild using `hmswitch`

      homeConfigurations = {

        "swarsel@home-manager" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = homeModules ++ mixedModules ++ [
            ./profiles/home-manager
          ];
        };

      };

      nixOnDroidConfigurations = {

        default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          modules = [
            ./profiles/mysticant/configuration.nix
          ];
        };

      };

    };
}
