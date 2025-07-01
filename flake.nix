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
    nixpkgs-kernel.url = "github:NixOS/nixpkgs/063f43f2dbdef86376cc29ad646c45c46e93234c?narHash=sha256-6m1Y3/4pVw1RWTsrkAK2VMYSzG4MMIj7sqUy7o8th1o%3D"; #specifically pinned for kernel version
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
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
    vbc-nix = {
      url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-topology.url = "github:oddlama/nix-topology";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nix/globals.nix
      ];
      flake = { config, ... }:
        let

          inherit (self) outputs;
          lib = (nixpkgs.lib // home-manager.lib).extend (_: _: { swarselsystems = import ./lib { inherit self lib inputs outputs systems; }; });


          linuxUser = "swarsel";
          macUser = "leon.schwarzaeugl";

          mkFullHost = host: type: {
            ${host} =
              let
                systemFunc = if (type == "nixos") then lib.nixosSystem else inputs.nix-darwin.lib.darwinSystem;
              in
              systemFunc {
                specialArgs = { inherit inputs outputs lib self; inherit (config) globals; };
                modules = [
                  {
                    node.name = host;
                    node.secretsDir = ./hosts/${type}/${host}/secrets;
                  }
                  # put inports here that are for all hosts
                  inputs.disko.nixosModules.disko
                  inputs.sops-nix.nixosModules.sops
                  inputs.impermanence.nixosModules.impermanence
                  inputs.lanzaboote.nixosModules.lanzaboote
                  inputs.fw-fanctrl.nixosModules.default
                  "${self}/hosts/${type}/${host}"
                  {
                    _module.args.primaryUser = linuxUser;
                  }
                ] ++
                (if (host == "iso") then [
                  inputs.nix-topology.nixosModules.default
                ] else
                  ([
                    # put nixos imports here that are for all servers and normal hosts
                    inputs.nix-topology.nixosModules.default
                    "${self}/modules/${type}/common"
                    inputs.stylix.nixosModules.stylix
                    inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
                  ] ++ (if (type == "nixos") then [
                    inputs.home-manager.nixosModules.home-manager
                    "${self}/profiles/nixos"
                    "${self}/modules/nixos/server"
                    "${self}/modules/nixos/optional"
                    {
                      home-manager.users."${linuxUser}".imports = [
                        # put home-manager imports here that are for all normal hosts
                        "${self}/modules/home/common"
                        "${self}/modules/home/server"
                        "${self}/modules/home/optional"
                        "${self}/profiles/home"
                      ];
                    }
                  ] else [
                    # put nixos imports here that are for darwin hosts
                    "${self}/modules/darwin/nixos/common"
                    "${self}/profiles/darwin"
                    inputs.home-manager.darwinModules.home-manager
                    {
                      home-manager.users."${macUser}".imports = [
                        # put home-manager imports here that are for darwin hosts
                        "${self}/modules/darwin/home"
                        "${self}/modules/home/server"
                        "${self}/modules/home/optional"
                        "${self}/profiles/home"
                      ];
                    }
                  ])
                  ));
              };
          };

          mkHalfHost = host: type: pkgs: {
            ${host} =
              let
                systemFunc = if (type == "home") then inputs.home-manager.lib.homeManagerConfiguration else inputs.nix-on-droid.lib.nixOnDroidConfiguration;
              in
              systemFunc
                {
                  inherit pkgs;
                  extraSpecialArgs = { inherit inputs outputs lib self; };
                  modules = [ "${self}/hosts/${type}/${host}" ];
                };
          };

          mkFullHostConfigs = hosts: type: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkFullHost host type) hosts);

          mkHalfHostConfigs = hosts: type: pkgs: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkHalfHost host type pkgs) hosts);

        in
        {
          inherit lib;

          # nixosModules = import ./modules/nixos { inherit lib; };
          # homeModules = import ./modules/home { inherit lib; };
          packages = lib.swarselsystems.forEachLinuxSystem (pkgs: import ./pkgs { inherit lib pkgs; });
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

            appSet // {
              default = appSet.swarsel-bootstrap;
            }
          );

          devShells = lib.swarselsystems.forAllSystems (system:
            let
              pkgs = lib.swarselsystems.pkgsFor.${system};
              checks = self.checks.${system};
            in
            {
              default = pkgs.mkShell {
                # plugin-files = ${pkgs.nix-plugins.overrideAttrs (o: {
                #   buildInputs = [pkgs.nixVersions.latest pkgs.boost];
                #   patches = (o.patches or []) ++ [ "${self}/nix/nix-plugins.patch" ];
                # })}/lib/nix/plugins
                NIX_CONFIG = ''
                  plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins
                  extra-builtins-file = ${self + /nix/extra-builtins.nix}
                '';
                inherit (checks.pre-commit-check) shellHook;

                buildInputs = checks.pre-commit-check.enabledPackages;
                nativeBuildInputs = [
                  (builtins.trace "alarm: we pinned nix_2_24 because of https://github.com/shlevy/nix-plugins/issues/20" pkgs.nixVersions.nix_2_24) # Always use the nix version from this flake's nixpkgs version, so that nix-plugins (below) doesn't fail because of different nix versions.
                  # pkgs.nix
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

          diskoConfigurations.default = import .templates/hosts/nixos/disk-config.nix;

          nixosConfigurations = mkFullHostConfigs (lib.swarselsystems.readHosts "nixos") "nixos";
          homeConfigurations = mkHalfHostConfigs (lib.swarselsystems.readHosts "home") "home" lib.swarselsystems.pkgsFor.x86_64-linux;
          darwinConfigurations = mkFullHostConfigs (lib.swarselsystems.readHosts "darwin") "darwin";
          nixOnDroidConfigurations = mkHalfHostConfigs (lib.swarselsystems.readHosts "android") "android" lib.swarselsystems.pkgsFor.aarch64-linux;

          topology = lib.swarselsystems.forEachSystem (pkgs: import inputs.nix-topology {
            inherit pkgs;
            modules = [
              "${self}/topology"
              { inherit (self) nixosConfigurations; }
            ];
          });

          nodes = config.nixosConfigurations;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
}
