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

    nix-secrets = {
      url = "git+ssh://git@github.com/Swarsel/nix-secrets.git?ref=main&shallow=1";
      flake = false;
      inputs = { };
    };

  };

  outputs =
    inputs@{ self
    , nixpkgs
    , home-manager
    , nix-darwin
    , systems
    , ...
    }:
    let

      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;

      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );
      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      mkFullHost = host: isNixos: {
        ${host} =
          let
            func = if isNixos then lib.nixosSystem else inputs.nix-darwin.lib.darwinSystem;
            systemFunc = func;
          in
          systemFunc {
            specialArgs = {
              inherit inputs outputs self;
              lib = lib.extend (_: _: { swarselsystems = import ./lib { inherit lib; }; });
            };
            modules = [ ./hosts/${if isNixos then "nixos" else "darwin"}/${host} ];
          };
      };
      mkFullHostConfigs = hosts: isNixos: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkFullHost host isNixos) hosts);
      readHosts = folder: lib.attrNames (builtins.readDir ./hosts/${folder});

      # NixOS modules that can only be used on NixOS systems
      nixModules = [
        inputs.stylix.nixosModules.stylix
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
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
      inherit nixModules;

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home;

      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      apps = forAllSystems (system: {
        default = self.apps.${system}.bootstrap;

        bootstrap = {
          type = "app";
          program = "${self.packages.${system}.bootstrap}/bin/bootstrap";
        };

        install = {
          type = "app";
          program = "${self.packages.${system}.swarsel-install}/bin/swarsel-install";
        };

        rebuild = {
          type = "app";
          program = "${self.packages.${system}.swarsel-rebuild}/bin/swarsel-rebuild";
        };
      });
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          checks = self.checks.${system};
        in
        {
          default = pkgs.mkShell {
            NIX_CONFIG = "experimental-features = nix-command flakes";
            inherit (checks.pre-commit-check) shellHook;
            buildInputs = checks.pre-commit-check.enabledPackages;
            nativeBuildInputs = [
              pkgs.nix
              pkgs.home-manager
              pkgs.git
              pkgs.just
              pkgs.age
              pkgs.ssh-to-age
              pkgs.sops
            ];
          };
        }
      );

      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./checks { inherit self inputs system pkgs; }
      );
      overlays = import ./overlays { inherit inputs; };


      nixosConfigurations =
        mkFullHostConfigs (readHosts "nixos") true;

      homeConfigurations = {

        "swarsel@home-manager" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = homeModules ++ mixedModules ++ [
            ./hosts/home-manager
          ];
        };

      };

      darwinConfigurations =
        mkFullHostConfigs (readHosts "darwin") false;

      nixOnDroidConfigurations = {

        magicant = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsFor.aarch64-linux;
          modules = [
            ./hosts/magicant
          ];
        };

      };

    };
}
