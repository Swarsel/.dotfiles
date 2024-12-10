{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.ngi0.nixos.org/"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
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
      url = "github:nix-community/nix-on-droid/release-24.05";
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

    impermanence.url = "github:nix-community/impermanence";

    zjstatus = {
      url = "github:dj95/zjstatus";
    };

    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ self
    , nixpkgs
    , nixpkgs-stable
    , home-manager
    , nix-darwin
    , systems
    , ...
    }:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;

      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );

      # NixOS modules that can only be used on NixOS systems
      nixModules = [
        inputs.stylix.nixosModules.stylix
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.disko.nixosModules.disko
        # inputs.impermanence.nixosModules.impermanence
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

      # For adding things to _module.args (making arguments available globally)
      # moduleArgs = [
      #   {
      #     _module.args = { inherit self; };
      #   }
      # ];
    in
    {

      inherit lib;
      inherit mixedModules;
      # inherit moduleArgs;
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home;

      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells = forEachSystem
        (pkgs:
          {
            default = pkgs.mkShell {
              NIX_CONFIG = "experimental-features = nix-command flakes";
              nativeBuildInputs = [ pkgs.nix pkgs.home-manager pkgs.git ];
            };
          });

      # this sets the formatter that is going to be used by nix fmt
      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./checks { inherit self inputs system pkgs; }
      );
      overlaysList = [
        (import ./overlays { inherit inputs; }).additions
        (import ./overlays { inherit inputs; }).modifications
        (import ./overlays { inherit inputs; }).nixpkgs-stable
        (import ./overlays { inherit inputs; }).zjstatus
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


        live = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          system = "x86_64-linux";
          modules = [
            {
              _module.args = { inherit self; };
            }
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./profiles/live
          ];
        };

        nbl-imba-2 = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = nixModules ++ [
            ./profiles/nbl-imba-2
          ];
        };

        winters = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [
            ./profiles/server/winters
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

      darwinConfigurations = {

        "nbm-imba-166" = inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./profiles/nbm-imba-166
          ];
        };

      };

      nixOnDroidConfigurations = {

        magicant = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsFor.aarch64-linux;
          modules = [
            ./profiles/magicant
          ];
        };

      };

    };
}
