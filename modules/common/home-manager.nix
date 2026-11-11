let
  mkExtraSpecialArgs =
    {
      inputs,
      configName,
      globals,
      minimal,
      nodes,
      outputs,
      ...
    }:
    {
      inherit (inputs) self nixgl;
      inherit
        inputs
        configName
        globals
        minimal
        nodes
        outputs
        ;
      inherit (outputs.swarselsystemsLib) root;
      inherit (outputs) lib;
    };
in
{
  flake.modules = {
    darwin.home-manager =
      {
        self,
        config,
        lib,
        globals,
        withHomeManager,
        ...
      }@args:
      {
        config = lib.mkIf withHomeManager {
          home-manager = {
            users.${globals.user.work}.imports = [
              self.modules.homeManager.profile-base
              self.modules.homeManager.settings
              { home.stateVersion = "23.05"; }
            ];
            extraSpecialArgs = mkExtraSpecialArgs args // {
              arch = config.node.arch;
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
        minimal,
        type,
        ...
      }@args:
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
            users.${mainUser}.imports = [
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
                node.name = config.node.name;
              }
            ];
            backupFileExtension = "hm-bak";
            extraSpecialArgs = mkExtraSpecialArgs args // {
              inherit arch type;
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
