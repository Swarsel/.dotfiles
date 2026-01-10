{ self, inputs, ... }:
{
  flake = { config, ... }:
    let
      inherit (self) outputs;
      inherit (outputs) lib homeLib;
      # lib = (inputs.nixpkgs.lib // inputs.home-manager.lib).extend  (_: _: { swarselsystems = import "${self}/lib" { inherit self lib inputs outputs; inherit (inputs) systems; }; });

      mkNixosHost = { minimal }: configName: arch:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs self minimal homeLib configName arch;
            inherit (config.pkgs.${arch}) lib;
            inherit (config) nodes topologyPrivate;
            globals = config.globals.${arch};
            type = "nixos";
            withHomeManager = true;
            extraModules = [ "${self}/modules/nixos/common/globals.nix" ];
          };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.home-manager.nixosModules.home-manager
            inputs.impermanence.nixosModules.impermanence
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.microvm.nixosModules.host
            inputs.microvm.nixosModules.microvm
            inputs.nix-index-database.nixosModules.nix-index
            inputs.nix-minecraft.nixosModules.minecraft-servers
            inputs.nix-topology.nixosModules.default
            inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
            inputs.simple-nixos-mailserver.nixosModules.default
            inputs.sops.nixosModules.sops
            inputs.stylix.nixosModules.stylix
            inputs.swarsel-nix.nixosModules.default
            inputs.nixos-nftables-firewall.nixosModules.default
            (inputs.nixos-extra-modules + "/modules/guests")
            (inputs.nixos-extra-modules + "/modules/interface-naming.nix")
            "${self}/hosts/nixos/${arch}/${configName}"
            "${self}/profiles/nixos"
            "${self}/modules/nixos"
            {
              _module.args.dns = inputs.dns;

              microvm.guest.enable = lib.mkDefault false;

              networking.hostName = lib.swarselsystems.mkStrong configName;

              node = {
                name = lib.mkForce configName;
                arch = lib.mkForce arch;
                type = lib.mkForce "nixos";
                secretsDir = ../hosts/nixos/${arch}/${configName}/secrets;
                configDir = ../hosts/nixos/${arch}/${configName};
                lockFromBootstrapping = lib.mkIf (!minimal) (lib.swarselsystems.mkStrong true);
              };

              swarselprofiles = {
                minimal = lib.mkIf minimal (lib.swarselsystems.mkStrong true);
              };

              swarselmodules.server = {
                ssh = lib.mkIf (!minimal) (lib.swarselsystems.mkStrong true);
              };

              swarselsystems = {
                mainUser = lib.swarselsystems.mkStrong "swarsel";
              };
            }
          ];
        };

      mkDarwinHost = { minimal }: configName: arch:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs lib outputs self minimal configName;
            inherit (config) nodes topologyPrivate;
            withHomeManager = true;
            globals = config.globals.${arch};
          };
          modules = [
            # inputs.disko.nixosModules.disko
            # inputs.sops.nixosModules.sops
            # inputs.impermanence.nixosModules.impermanence
            # inputs.lanzaboote.nixosModules.lanzaboote
            # inputs.fw-fanctrl.nixosModules.default
            # inputs.nix-topology.nixosModules.default
            inputs.home-manager.darwinModules.home-manager
            "${self}/hosts/darwin/${arch}/${configName}"
            "${self}/modules/nixos/darwin"
            # needed for infrastructure
            "${self}/modules/shared/meta.nix"
            "${self}/modules/nixos/common/globals.nix"
            {
              node = {
                name = lib.mkForce configName;
                arch = lib.mkForce arch;
                type = lib.mkForce "darwin";
                secretsDir = ../hosts/darwin/${arch}/${configName}/secrets;
              };
            }
          ];
        };

      mkHalfHost = configName: type: arch:
        let
          systemFunc = if (type == "home") then inputs.home-manager.lib.homeManagerConfiguration else inputs.nix-on-droid.lib.nixOnDroidConfiguration;
          pkgs = lib.swarselsystems.pkgsFor.${arch};
        in
        systemFunc {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs lib outputs self configName arch type;
            inherit (config) nodes topologyPrivate;
            globals = config.globals.${arch};
            minimal = false;
          };
          modules = [
            inputs.stylix.homeModules.stylix
            inputs.nix-index-database.homeModules.nix-index
            inputs.sops.homeManagerModules.sops
            inputs.spicetify-nix.homeManagerModules.default
            inputs.swarsel-nix.homeModules.default
            "${self}/hosts/${type}/${arch}/${configName}"
            "${self}/profiles/home"
            "${self}/modules/nixos/common/pii.nix"
            {
              node = {
                name = lib.mkForce configName;
                arch = lib.mkForce arch;
                type = lib.mkForce type;
                secretsDir = ../hosts/${type}/${arch}/${configName}/secrets;
              };
            }
          ];
        };

      linuxArches = [ "x86_64-linux" "aarch64-linux" ];
      darwinArches = [ "x86_64-darwin" "aarch64-darwin" ];
      mkArches = type: if (type == "nixos") then linuxArches else if (type == "darwin") then darwinArches else linuxArches ++ darwinArches;

      readHostDirs = hostDir:
        if builtins.pathExists hostDir then
          builtins.attrNames
            (
              lib.filterAttrs (_: type: type == "directory")
                (builtins.readDir hostDir)
            ) else [ ];

      mkHalfHostsForArch = type: arch:
        let
          hostDir = "${self}/hosts/${type}/${arch}";
          hosts = readHostDirs hostDir;
        in
        lib.genAttrs hosts (host: mkHalfHost host type arch);

      mkHostsForArch = type: arch: minimal:
        let
          hostDir = "${self}/hosts/${type}/${arch}";
          hosts = readHostDirs hostDir;
        in
        if (type == "nixos") then
          lib.genAttrs hosts (host: mkNixosHost { inherit minimal; } host arch)
        else if (type == "darwin") then
          lib.genAttrs hosts (host: mkDarwinHost { inherit minimal; } host arch)
        else { };

      mkConfigurationsPerArch = type: minimal:
        let
          arches = mkArches type;
          toMake = if (minimal == null) then (arch: _: mkHalfHostsForArch type arch) else (arch: _: mkHostsForArch type arch minimal);
        in
        lib.concatMapAttrs toMake
          (lib.listToAttrs (map (a: { name = a; value = { }; }) arches));

      halfConfigurationsPerArch = type: mkConfigurationsPerArch type null;
      configurationsPerArch = type: minimal: mkConfigurationsPerArch type minimal;

    in
    {
      nixosConfigurations = configurationsPerArch "nixos" false;
      nixosConfigurationsMinimal = configurationsPerArch "nixos" true;
      darwinConfigurations = configurationsPerArch "darwin" false;
      darwinConfigurationsMinimal = configurationsPerArch "darwin" true;
      homeConfigurations = halfConfigurationsPerArch "home";
      nixOnDroidConfigurations = halfConfigurationsPerArch "android";

      guestConfigurations = lib.flip lib.concatMapAttrs config.nixosConfigurations (
        _: node:
          lib.flip lib.mapAttrs' (node.config.guests or { }) (
            guestName: guestDef:
              lib.nameValuePair guestDef.nodeName node.config.microvm.vms.${guestName}.config
          )
      );

      diskoConfigurations.default = import "${self}/files/templates/hosts/nixos/disk-config.nix";

      nodes = config.nixosConfigurations
        // config.darwinConfigurations
        // config.guestConfigurations;

      "@" = lib.mapAttrs (_: v: v.config.system.build.toplevel) config.nodes;
    };
}
