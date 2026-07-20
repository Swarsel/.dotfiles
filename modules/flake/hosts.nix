{ self, inputs, ... }:
{
  flake-file.inputs = {
    disko = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/disko";
    };

    microvm = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:astro/microvm.nix";
    };

    nix-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:lnl7/nix-darwin";
    };

    nix-index-database = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nix-index-database";
    };

    nix-on-droid = {
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:nix-community/nix-on-droid/release-24.05";
    };
  };

  flake =
    { config, ... }:
    let
      inherit (self) outputs;
      inherit (outputs) lib homeLib;

      mkNixosHost =
        { minimal }:
        configName: arch:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.disko
            inputs.home-manager.nixosModules.home-manager
            inputs.microvm.nixosModules.host
            inputs.microvm.nixosModules.microvm
            inputs.nix-index-database.nixosModules.nix-index
            inputs.swarsel-nix.nixosModules.default
            (inputs.nixos-extra-modules + "/modules/guests")
            (inputs.nixos-extra-modules + "/modules/interface-naming.nix")
            "${self}/hosts/nixos/${arch}/${configName}"
            self.modules.nixos.profile-base
            {
              swarselsystems.mainUser = lib.swarselsystems.mkStrong "swarsel";
              microvm.guest.enable = lib.mkDefault false;
              networking.hostName = lib.swarselsystems.mkStrong configName;
              node = {
                arch = lib.mkForce arch;
                configDir = ../../hosts/nixos/${arch}/${configName};
                lockFromBootstrapping = lib.mkIf (!minimal) (lib.swarselsystems.mkStrong true);
                name = lib.mkForce configName;
                secretsDir = ../../hosts/nixos/${arch}/${configName}/secrets;
                type = lib.mkForce "nixos";
              };
            }
          ]
          ++ lib.optionals minimal [
            self.modules.nixos.profile-minimal
          ];
          specialArgs = {
            inherit
              self
              inputs
              arch
              configName
              homeLib
              minimal
              outputs
              ;
            inherit (config.pkgs.${arch}) lib;
            inherit (config) nodes topologyPrivate;
            globals = config.globals.${arch};
            extraModules = [ ];
            type = "nixos";
            withHomeManager = true;
          };
        };

      mkDarwinHost =
        { minimal }:
        configName: arch:
        inputs.nix-darwin.lib.darwinSystem {
          modules = [
            inputs.home-manager.darwinModules.home-manager
            "${self}/hosts/darwin/${arch}/${configName}"
            {
              node = {
                arch = lib.mkForce arch;
                name = lib.mkForce configName;
                secretsDir = ../../hosts/darwin/${arch}/${configName}/secrets;
                type = lib.mkForce "darwin";
              };
            }
          ];
          specialArgs = {
            inherit
              self
              inputs
              lib
              configName
              minimal
              outputs
              ;
            inherit (config) nodes topologyPrivate;
            globals = config.globals.${arch};
            withHomeManager = true;
          };
        };

      mkHalfHost =
        configName: type: arch:
        let
          pkgs = lib.swarselsystems.pkgsFor.${arch};
          extraSpecialArgs = {
            inherit
              self
              inputs
              lib
              arch
              configName
              outputs
              type
              ;
            inherit (config) nodes topologyPrivate;
            globals = config.globals.${arch};
            minimal = false;
          };
          nodeModule = {
            node = {
              arch = lib.mkForce arch;
              name = lib.mkForce configName;
              secretsDir = ../../hosts/${type}/${arch}/${configName}/secrets;
              type = lib.mkForce type;
            };
          };
          homeModules = [
            inputs.nix-index-database.homeModules.nix-index
            inputs.swarsel-nix.homeModules.default
            inputs.glide-nix.homeModules.default
            self.modules.generic.pii
            nodeModule
          ];
        in
        if (type == "home") then
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs extraSpecialArgs;
            modules = homeModules ++ [ "${self}/hosts/${type}/${arch}/${configName}" ];
          }
        else
          inputs.nix-on-droid.lib.nixOnDroidConfiguration {
            inherit pkgs extraSpecialArgs;
            modules = [
              "${self}/hosts/${type}/${arch}/${configName}"
              {
                home-manager = {
                  config.imports = homeModules ++ [
                    self.modules.homeManager.profile-base
                    { home.stateVersion = "23.05"; }
                  ];
                  extraSpecialArgs = extraSpecialArgs // {
                    nixosConfig = null;
                  };
                };
              }
            ];
          };

      inherit (lib.swarselsystems) darwinSystems linuxSystems;
      mkArches =
        type:
        if (type == "nixos") then
          linuxSystems
        else if (type == "darwin") then
          darwinSystems
        else
          linuxSystems ++ darwinSystems;

      readHostsOfType =
        entryType: hostDir:
        if builtins.pathExists hostDir then
          builtins.attrNames (lib.filterAttrs (_: type: type == entryType) (builtins.readDir hostDir))
        else
          [ ];

      readHostDirs = readHostsOfType "directory";

      utilityHostArches = lib.foldl' (
        acc: arch:
        acc
        // lib.genAttrs (readHostsOfType "symlink" "${self}/hosts/nixos/${arch}") (
          host: (acc.${host} or [ ]) ++ [ arch ]
        )
      ) { } lib.swarselsystems.linuxSystems;

      utilityHostName =
        host: arch:
        let
          arches = utilityHostArches.${host};
          primary = if builtins.elem "x86_64-linux" arches then "x86_64-linux" else builtins.head arches;
        in
        if arch == primary then host else "${host}-${arch}";

      utilityHostNames =
        lib.concatLists (
          lib.mapAttrsToList (host: arches: map (utilityHostName host) arches) utilityHostArches
        )
        ++ readHostDirs "${self}/hosts/utility";

      mkHalfHostsForArch =
        type: arch:
        let
          hostDir = "${self}/hosts/${type}/${arch}";
          hosts = readHostDirs hostDir;
        in
        lib.genAttrs hosts (host: mkHalfHost host type arch);

      mkHostsForArch =
        type: arch: minimal:
        let
          hostDir = "${self}/hosts/${type}/${arch}";
          hosts = readHostDirs hostDir;
        in
        if (type == "nixos") then
          lib.genAttrs hosts (host: mkNixosHost { inherit minimal; } host arch)
          // lib.listToAttrs (
            map
              (host: lib.nameValuePair (utilityHostName host arch) (mkNixosHost { inherit minimal; } host arch))
              (
                builtins.filter (host: builtins.elem arch utilityHostArches.${host}) (
                  builtins.attrNames utilityHostArches
                )
              )
          )
        else if (type == "darwin") then
          lib.genAttrs hosts (host: mkDarwinHost { inherit minimal; } host arch)
        else
          { };

      mkConfigurationsPerArch =
        type: minimal:
        let
          arches = mkArches type;
          toMake =
            if (minimal == null) then
              (arch: _: mkHalfHostsForArch type arch)
            else
              (arch: _: mkHostsForArch type arch minimal);
        in
        lib.concatMapAttrs toMake (
          lib.listToAttrs (
            map (a: {
              name = a;
              value = { };
            }) arches
          )
        );

      halfConfigurationsPerArch = type: mkConfigurationsPerArch type null;
      configurationsPerArch = type: minimal: mkConfigurationsPerArch type minimal;

    in
    rec {
      "@" = lib.mapAttrs (_: v: v.config.system.build.toplevel) config.nodes;
      darwinConfigurations = configurationsPerArch "darwin" false;
      darwinConfigurationsMinimal = configurationsPerArch "darwin" true;
      diskoConfigurations.default = import "${self}/files/templates/hosts/nixos/disk-config.nix";
      guestConfigurations = lib.flip lib.concatMapAttrs config.nixosConfigurations (
        _: node:
        lib.flip lib.mapAttrs' (node.config.guests or { }) (
          guestName: guestDef: lib.nameValuePair guestDef.nodeName node.config.microvm.vms.${guestName}.config
        )
      );
      guestResources = lib.mapAttrs (
        name: _:
        let
          f =
            arg:
            lib.foldr (base: acc: base + acc) 0 (
              map (node: nodes."${name}-${node}".config.microvm.${arg}) (
                builtins.attrNames nodes.${name}.config.guests
              )
            );
        in
        {
          mem = f "mem";
          vcpu = f "vcpu";
        }
      ) nodes;
      homeConfigurations = halfConfigurationsPerArch "home";
      nixOnDroidConfigurations = halfConfigurationsPerArch "android";
      nixosConfigurations = configurationsPerArch "nixos" false;
      nixosConfigurationsMinimal = configurationsPerArch "nixos" true;
      nodes = builtins.removeAttrs (
        config.nixosConfigurations // config.darwinConfigurations // config.guestConfigurations
      ) utilityHostNames;
    };
}
