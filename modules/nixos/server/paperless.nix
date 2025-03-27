{ lib, config, ... }:
{
  options.swarselsystems.server.paperless = lib.mkEnableOption "enable paperless on server";
  config = lib.mkIf config.swarselsystems.server.paperless {

    users.users.paperless = {
      extraGroups = [ "users" ];
    };


    sops.secrets.paperless_admin = { owner = "paperless"; };

    services.paperless = {
      enable = true;
      mediaDir = "/Vault/Eternor/Paperless";
      dataDir = "/Vault/data/paperless";
      user = "paperless";
      port = 28981;
      passwordFile = config.sops.secrets.paperless_admin.path;
      address = "127.0.0.1";
      settings = {
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_URL = "https://scan.swarsel.win";
        PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
          optimize = 1;
          invalidate_digital_signatures = true;
          pdfa_image_compression = "lossless";
        };
      };
    };

    services.nginx = {
      virtualHosts = {
        "scan.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:28981";
              extraConfig = ''
                client_max_body_size    0;
              '';
            };
          };
        };
      };
    };
  };

}
