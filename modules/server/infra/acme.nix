{
  flake.modules.nixos.acme =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.repo.secrets.common) dnsBase dnsMail dnsProvider;

      sopsFile = self + "/secrets/nginx/acme.json";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "acme" ];
        sops = {
          secrets.acme-creds = {
            inherit sopsFile;
            format = "json";
            group = "acme";
            key = "";
            mode = "0660";
          };
          templates."certs.secret".content = ''
            ACME_DNS_API_BASE = ${dnsBase}
            ACME_DNS_STORAGE_PATH=${config.sops.secrets.acme-creds.path}
          '';
        };
        users = {
          groups.acme.members = lib.mkIf (builtins.elem "nginx" config.swarselsystems.enabledServerModules) [
            "nginx"
          ];
          persistentIds.acme = confLib.mkIds 967;
        };
        environment = {
          persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
            directories = [ { directory = "/var/lib/acme"; } ];
          };
          systemPackages = with pkgs; [
            lego
          ];
        };
        security.acme = {
          acceptTerms = true;
          certs."${globals.domains.main}".domain = "*.${globals.domains.main}";
          defaults = {
            inherit dnsProvider;
            dnsPropagationCheck = true;
            email = dnsMail;
            environmentFile = "${config.sops.templates."certs.secret".path}";
            keyType = "ec384";
            reloadServices = [ "nginx" ];
          };
        };

      };
    }

  ;
}
