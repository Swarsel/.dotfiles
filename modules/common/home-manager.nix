{
  flake.modules = {
    darwin.home-manager = { self, lib, config, inputs, outputs, globals, nodes, minimal, configName, withHomeManager, ... }:
      {
        config = lib.mkIf withHomeManager {
          home-manager = {
            users.${globals.user.work}.imports = [
              self.modules.homeManager.profile-base
              self.modules.homeManager.settings
              { home.stateVersion = "23.05"; }
            ];
            extraSpecialArgs = {
              inherit (inputs) self nixgl;
              inherit inputs outputs globals nodes minimal configName;
              arch = config.node.arch;
              type = "darwin";
              lib = outputs.homeLib;
              nixosConfig = config;
            };
          };
        };
      };

    nixos.home-manager = { self, inputs, config, lib, homeLib, outputs, globals, nodes, minimal, configName, arch, type, ... }:
      let
        inherit (config.swarselsystems) isServer isMicroVM mainUser;
        homeSwarsel = config.home-manager.users.${mainUser}.swarselsystems or { };
      in
      {
        config = {
          sops = {
            secrets = lib.mapAttrs (_: v: v // { owner = mainUser; }) (homeSwarsel.homeSopsSecrets or { });
            templates = lib.mapAttrs (_: v: v // { owner = mainUser; }) (homeSwarsel.homeSopsTemplates or { });
          };

          home-manager = lib.mkIf (!isServer && !isMicroVM) {
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            backupFileExtension = "hm-bak";
            overwriteBackup = true;
            users.${config.swarselsystems.mainUser}.imports = [
              inputs.swarsel-nix.homeModules.default
              {
                imports = [
                  self.modules.homeManager.profile-base
                ] ++ lib.optionals minimal [
                  self.modules.homeManager.profile-minimal
                ];
                home.stateVersion = lib.mkDefault config.system.stateVersion;
              }
            ];
            extraSpecialArgs = {
              inherit (inputs) self nixgl;
              inherit inputs outputs globals nodes minimal configName arch type;
              lib = homeLib;
            };
          };
        };
      };
  };
}
