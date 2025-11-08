{ self, inputs, ... }:
{
  flake = { config, ... }:
    let
      inherit (self) outputs;
      inherit (outputs) lib homeLib;
      # lib = (inputs.nixpkgs.lib // inputs.home-manager.lib).extend  (_: _: { swarselsystems = import "${self}/lib" { inherit self lib inputs outputs; inherit (inputs) systems; }; });

      mkNixosHost = { minimal }: configName:
        let
          sys = "x86_64-linux";
          # lib = config.pkgsPre.${sys}.lib // {
          #   inherit (inputs.home-manager.lib) hm;
          #   swarselsystems = self.outputs.swarselsystemsLib;
          # };

          # lib = config.pkgsPre.${sys}.lib // {
          #   inherit (inputs.home-manager.lib) hm;
          #   swarselsystems = self.outputs.swarselsystemsLib;
          # };
          inherit (config.pkgs.${sys}) lib;
        in
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs self minimal configName;
            inherit lib homeLib;
            inherit (config) globals nodes;
          };
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
            (inputs.nixos-extra-modules + "/modules/guests")
            "${self}/hosts/nixos/${configName}"
            "${self}/profiles/nixos"
            "${self}/modules/nixos"
            {

              microvm.guest.enable = lib.mkDefault false;

              node = {
                name = lib.mkForce configName;
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
            inherit inputs lib outputs self minimal configName;
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
              node.name = lib.mkForce configName;
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
                inherit inputs lib outputs self configName;
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

      homeConfigurations =
        let
          inherit (lib.swarselsystems) pkgsFor readHosts;
        in
        mkHalfHostConfigs (readHosts "home") "home" pkgsFor.x86_64-linux
        // mkHalfHostConfigs (readHosts "home") "home" pkgsFor.aarch64-linux;

      nixOnDroidConfigurations =
        let
          inherit (lib.swarselsystems) pkgsFor readHosts;
        in
        mkHalfHostConfigs (readHosts "android") "android" pkgsFor.aarch64-linux;

      guestConfigurations = lib.flip lib.concatMapAttrs config.nixosConfigurations (
        _: node:
          lib.flip lib.mapAttrs' (node.config.microvm.vms or { }) (
            guestName: guestDef:
              lib.nameValuePair guestDef.nodeName node.config.microvm.vms.${guestName}.config
          )
      );

      diskoConfigurations.default = import "${self}/files/templates/hosts/nixos/disk-config.nix";

      nodes = config.nixosConfigurations
        // config.darwinConfigurations
        // config.guestConfigurations;
    };
}
