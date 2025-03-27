{ lib, config, ... }:
{
  options.swarselsystems.server.freshrss = lib.mkEnableOption "enable freshrss on server";
  config = lib.mkIf config.swarselsystems.server.freshrss {

    users.users.freshrss = {
      extraGroups = [ "users" ];
      group = "freshrss";
      isSystemUser = true;
    };

    users.groups.freshrss = { };

    sops.secrets.fresh = { owner = "freshrss"; };

    services.freshrss = {
      enable = true;
      virtualHost = "signpost.swarsel.win";
      baseUrl = "https://signpost.swarsel.win";
      # authType = "none";
      dataDir = "/Vault/data/tt-rss";
      defaultUser = "Swarsel";
      passwordFile = config.sops.secrets.fresh.path;
    };

    services.nginx = {
      virtualHosts = {
        "signpost.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
        };
      };
    };
  };

}
