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
      inherit (config.repo.secrets.common) dnsMail dnsProvider;
      inherit (globals.general) acmeDnsServer;
      inherit (confLib.static) webProxyIf;

      acmeDns = globals.services.acme-dns;

      sopsFile = self + "/secrets/nginx/acme.json";
      probeDomain = "ssl.${globals.domains.main}";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "acme" ];
        globals = {
          monitoring.tls.${config.node.name} = {
            address = "127.0.0.1:443";
            network = "local-${config.node.name}";
            serverName = probeDomain;
          };
          networks.${webProxyIf}.hosts.${acmeDnsServer}.firewallRuleForNode.${config.node.name}.allowedTCPPorts =
            [
              acmeDns.extraConfig.port
            ];
        };
        sops = {
          secrets.acme-creds = {
            inherit sopsFile;
            format = "json";
            group = "acme";
            key = "";
            mode = "0660";
          };
          templates."certs.secret".content = ''
            ACME_DNS_API_BASE = http://${acmeDns.serviceAddress}:${toString acmeDns.extraConfig.port}
            ACME_DNS_STORAGE_PATH=${config.sops.secrets.acme-creds.path}
          '';
        };
        users = {
          groups.acme.members = lib.mkIf (builtins.elem "nginx" config.swarselsystems.enabledServerModules) [
            "nginx"
          ];
          persistentIds.acme = confLib.mkIds 967;
        };
        services.nginx.virtualHosts.${probeDomain} = {
          acmeRoot = null;
          locations."/".return = "444";
          onlySSL = true;
          useACMEHost = globals.domains.main;
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
