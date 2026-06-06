{
  flake.modules.nixos.acme =
    { self, pkgs, lib, config, globals, confLib, ... }:
    let
      inherit (config.repo.secrets.common) dnsProvider dnsBase dnsMail;

      sopsFile = self + "/secrets/nginx/acme.json";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "acme" ];
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
          groups.acme.members = lib.mkIf (builtins.elem "nginx" config.swarselsystems.enabledServerModules) [ "nginx" ];
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            inherit dnsProvider;
            email = dnsMail;
            environmentFile = "${config.sops.templates."certs.secret".path}";
            reloadServices = [ "nginx" ];
            dnsPropagationCheck = true;
            keyType = "ec384";
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

  ;
}
