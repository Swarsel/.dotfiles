{
  flake.modules.homeManager.attic-client = { config, globals, confLib, ... }:
    let
      inherit (config.swarselsystems) mainUser;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "attic-client" ];

        swarselsystems.homeSopsSecrets = {
          attic-cache-key = { };
        };

        swarselservices.attic-client = {
          enable = true;
          servers.${mainUser} = {
            endpoint = "https://${globals.services.attic.domain}";
            tokenFile = confLib.getConfig.sops.secrets.attic-cache-key.path;
          };
          watchStore = [ "${mainUser}:${mainUser}" ];
        };

        systemd.user.services.attic-config.Unit.After = [ "sops-nix.service" ];
      };
    };
}
