{
  flake.modules.homeManager.gammastep =
    {
      config,
      lib,
      confLib,
      nixosConfig ? null,
      ...
    }:
    let
      inherit (confLib.getConfig.repo.secrets.common.location) latitude longitude;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "gammastep" ];
        services.gammastep = lib.mkIf ((nixosConfig != null) && !config.swarselsystems.isPublic) {
          inherit latitude longitude;
          enable = true;
          provider = "manual";
        };
        systemd.user.services.gammastep = confLib.overrideTarget "sway-session.target";
      };
    };
}
