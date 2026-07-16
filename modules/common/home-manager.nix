{
  flake.modules = {
    darwin.home-manager =
      {
        self,
        inputs,
        config,
        lib,
        configName,
        globals,
        minimal,
        nodes,
        outputs,
        withHomeManager,
        ...
      }:
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
              inherit
                inputs
                configName
                globals
                minimal
                nodes
                outputs
                ;
              arch = config.node.arch;
              lib = outputs.homeLib;
              nixosConfig = config;
              type = "darwin";
            };
          };
        };
      };

    nixos.home-manager =
      {
        self,
        inputs,
        config,
        lib,
        arch,
        configName,
        globals,
        homeLib,
        minimal,
        nodes,
        outputs,
        type,
        ...
      }:
      let
        inherit (config.swarselsystems) isMicroVM isServer mainUser;
        homeSwarsel = config.home-manager.users.${mainUser}.swarselsystems or { };
      in
      {
        config = {
          sops = {
            secrets = lib.mapAttrs (_: v: v // { owner = mainUser; }) (homeSwarsel.homeSopsSecrets or { });
            templates = lib.mapAttrs (_: v: v // { owner = mainUser; }) (homeSwarsel.homeSopsTemplates or { });
          };
          home-manager = lib.mkIf (!isServer && !isMicroVM) {
            users.${config.swarselsystems.mainUser}.imports = [
              inputs.swarsel-nix.homeModules.default
              inputs.glide-nix.homeModules.default
              {
                imports = [
                  self.modules.homeManager.profile-base
                ]
                ++ lib.optionals minimal [
                  self.modules.homeManager.profile-minimal
                ];
                home.stateVersion = lib.mkDefault config.system.stateVersion;
              }
            ];
            backupFileExtension = "hm-bak";
            extraSpecialArgs = {
              inherit (inputs) self nixgl;
              inherit
                inputs
                arch
                configName
                globals
                minimal
                nodes
                outputs
                type
                ;
              lib = homeLib;
            };
            overwriteBackup = true;
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
          };
        };
      };
  };
}
