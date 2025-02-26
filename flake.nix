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
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default-linux";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    nixgl.url = "github:guibou/nixGL";
    stylix.url = "github:danth/stylix";
    sops-nix.url = "github:Mic92/sops-nix";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
    };
    nswitch-rcm-nix = {
      url = "github:Swarsel/nswitch-rcm-nix";
    };
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
    nix-topology.url = "github:oddlama/nix-topology";

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
      lib = (nixpkgs.lib // home-manager.lib).extend (_: _: { swarselsystems = import ./lib { inherit self lib inputs outputs systems; }; });

    in
    {

      inherit lib;

      nixosModules = import ./modules/nixos { inherit lib; };
      homeModules = import ./modules/home { inherit lib; };
      packages = lib.swarselsystems.forEachSystem (pkgs: import ./pkgs { inherit lib pkgs; });
      formatter = lib.swarselsystems.forEachSystem (pkgs: pkgs.nixpkgs-fmt);
      overlays = import ./overlays { inherit self lib inputs; };

      apps = lib.swarselsystems.forAllSystems (system:
        let
          appNames = [
            "swarsel-bootstrap"
            "swarsel-install"
            "swarsel-rebuild"
            "swarsel-postinstall"
          ];
          appSet = lib.swarselsystems.mkApps system appNames self;
        in
        {
          inherit appSet;
          default = appSet.bootstrap;
        });

      devShells = lib.swarselsystems.forAllSystems (system:
        let
          pkgs = lib.swarselsystems.pkgsFor.${system};
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
              pkgs.statix
              pkgs.deadnix
              pkgs.nixpkgs-fmt
            ];
          };
        }
      );

      templates = import ./templates { inherit lib; };

      checks = lib.swarselsystems.forAllSystems (system:
        let
          pkgs = lib.swarselsystems.pkgsFor.${system};
        in
        import ./checks { inherit self inputs system pkgs; }
      );


      nixosConfigurations =
        lib.swarselsystems.mkFullHostConfigs (lib.swarselsystems.readHosts "nixos") "nixos";
      homeConfigurations =

        # "swarsel@home-manager" = inputs.home-manager.lib.homeManagerConfiguration {
        #  pkgs = lib.swarselsystems.pkgsFor.x86_64-linux;
        #  extraSpecialArgs = { inherit inputs outputs; };
        #   modules = homeModules ++ mixedModules ++ [
        #     ./hosts/home-manager
        #   ];
        # };

        lib.swarselsystems.mkHalfHostConfigs (lib.swarselsystems.readHosts "home") "home" lib.swarselsystems.pkgsFor.x86_64-linux;
      darwinConfigurations =
        lib.swarselsystems.mkFullHostConfigs (lib.swarselsystems.readHosts "darwin") "darwin";
      nixOnDroidConfigurations =

        # magicant = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        #  pkgs = lib.swarselsystems.pkgsFor.aarch64-linux;
        #   modules = [
        #     ./hosts/magicant
        #   ];
        # };

        lib.swarselsystems.mkHalfHostConfigs (lib.swarselsystems.readHosts "android") "android" lib.swarselsystems.pkgsFor.aarch64-linux;


      topology =

        lib.swarselsystems.forEachSystem (pkgs: import inputs.nix-topology {
          inherit pkgs;
          modules = [
            # Your own file to define global topology. Works in principle like a nixos module but uses different options.
            # ./topology.nix
            { inherit (self) nixosConfigurations; }
          ];
        });

    };
}
