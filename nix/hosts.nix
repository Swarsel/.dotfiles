{ self, inputs, ... }:
{
  flake = { config, ... }:
    let
      inherit (self) outputs;
      inherit (outputs) lib;
      # lib = (inputs.nixpkgs.lib // inputs.home-manager.lib).extend  (_: _: { swarselsystems = import "${self}/lib" { inherit self lib inputs outputs; inherit (inputs) systems; }; });

      mkNixosHost = { minimal }: configName:
        lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib self minimal configName; inherit (config) globals nodes; };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.sops-nix.nixosModules.sops
            inputs.impermanence.nixosModules.impermanence
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.nix-topology.nixosModules.default
            inputs.home-manager.nixosModules.home-manager
            inputs.stylix.nixosModules.stylix
            inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
            # inputs.swarsel-modules.nixosModules.default
            inputs.swarsel-nix.nixosModules.default
            inputs.niri-flake.nixosModules.niri
            inputs.microvm.nixosModules.host
            inputs.microvm.nixosModules.microvm
            "${self}/hosts/nixos/${configName}"
            "${self}/profiles/nixos"
            "${self}/modules/nixos"
            {

              microvm.guest.enable = lib.mkDefault false;

              node = {
                name = configName;
                secretsDir = ../hosts/nixos/${configName}/secrets;
              };

              swarselprofiles = {
                minimal = lib.mkIf minimal (lib.mkDefault true);
              };

              swarselmodules.server = {
                ssh = lib.mkIf (!minimal) (lib.mkDefault true);
              };

              swarselsystems = {
                mainUser = lib.mkDefault "swarsel";
              };
            }
          ];
        };

      mkDarwinHost = { minimal }: configName:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs outputs lib self minimal configName;
            inherit (config) globals nodes;
          };
          modules = [
            # inputs.disko.nixosModules.disko
            # inputs.sops-nix.nixosModules.sops
            # inputs.impermanence.nixosModules.impermanence
            # inputs.lanzaboote.nixosModules.lanzaboote
            # inputs.fw-fanctrl.nixosModules.default
            # inputs.nix-topology.nixosModules.default
            inputs.home-manager.darwinModules.home-manager
            "${self}/hosts/darwin/${configName}"
            "${self}/modules/nixos/darwin"
            # needed for infrastructure
            "${self}/modules/nixos/common/meta.nix"
            "${self}/modules/nixos/common/globals.nix"
            {
              node.name = configName;
              node.secretsDir = ../hosts/darwin/${configName}/secrets;

            }
          ];
        };

      mkHalfHost = configName: type: pkgs: {
        ${configName} =
          let
            systemFunc = if (type == "home") then inputs.home-manager.lib.homeManagerConfiguration else inputs.nix-on-droid.lib.nixOnDroidConfiguration;
          in
          systemFunc
            {
              inherit pkgs;
              extraSpecialArgs = {
                inherit inputs outputs lib self configName;
                inherit (config) globals nodes;
                minimal = false;
              };
              modules = [
                inputs.stylix.homeModules.stylix
                inputs.niri-flake.homeModules.niri
                inputs.nix-index-database.homeModules.nix-index
                # inputs.sops-nix.homeManagerModules.sops
                inputs.spicetify-nix.homeManagerModules.default
                inputs.swarsel-nix.homeModules.default
                "${self}/hosts/${type}/${configName}"
                "${self}/profiles/home"
              ];
            };
      };

      mkHalfHostConfigs = hosts: type: pkgs: lib.foldl (acc: set: acc // set) { } (lib.map (name: mkHalfHost name type pkgs) hosts);
      nixosHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${self}/hosts/nixos"));
      darwinHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${self}/hosts/darwin"));
    in
    {
      nixosConfigurations = lib.genAttrs nixosHosts (mkNixosHost {
        minimal = false;
      });
      nixosConfigurationsMinimal = lib.genAttrs nixosHosts (mkNixosHost {
        minimal = true;
      });
      darwinConfigurations = lib.genAttrs darwinHosts (mkDarwinHost {
        minimal = false;
      });
      darwinConfigurationsMinimal = lib.genAttrs darwinHosts (mkDarwinHost {
        minimal = true;
      });

      # TODO: Build these for all architectures
      homeConfigurations = mkHalfHostConfigs (lib.swarselsystems.readHosts "home") "home" lib.swarselsystems.pkgsFor.x86_64-linux // mkHalfHostConfigs (lib.swarselsystems.readHosts "home") "home" lib.swarselsystems.pkgsFor.aarch64-linux;
      nixOnDroidConfigurations = mkHalfHostConfigs (lib.swarselsystems.readHosts "android") "android" lib.swarselsystems.pkgsFor.aarch64-linux;

      diskoConfigurations.default = import "${self}/files/templates/hosts/nixos/disk-config.nix";

      nodes = config.nixosConfigurations // config.darwinConfigurations;

    };
}
