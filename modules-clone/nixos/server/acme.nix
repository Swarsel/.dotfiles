{ self, pkgs, lib, config, globals, confLib, ... }:
let
  inherit (config.repo.secrets.common) dnsProvider dnsBase dnsMail;

  sopsFile = self + "/secrets/nginx/acme.json";
in
{
  options.swarselmodules.server.acme = lib.mkEnableOption "enable acme on server";
  config = lib.mkIf config.swarselmodules.server.acme {
    environment.systemPackages = with pkgs; [
      lego
    ];

    sops = {
      secrets = {
        acme-creds = { format = "json"; key = ""; group = "acme"; inherit sopsFile; mode = "0660"; };
      };
      templates."certs.secret".content = ''
        ACME_DNS_API_BASE = ${dnsBase}
        ACME_DNS_STORAGE_PATH=${config.sops.secrets.acme-creds.path}
      '';
    };

    users = {
      persistentIds.acme = confLib.mkIds 967;
      groups.acme.members = lib.mkIf config.swarselmodules.server.nginx [ "nginx" ];
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        inherit dnsProvider;
        email = dnsMail;
        environmentFile = "${config.sops.templates."certs.secret".path}";
        reloadServices = [ "nginx" ];
        dnsPropagationCheck = true;
      };
      certs."${globals.domains.main}" = {
        domain = "*.${globals.domains.main}";
      };
    };

    environment.persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
      directories = [{ directory = "/var/lib/acme"; }];
    };

  };
}
