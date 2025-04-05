{ pkgs, lib, config, ... }:
{
  options.swarselsystems.server.nginx = lib.mkEnableOption "enable nginx on server";
  config = lib.mkIf config.swarselsystems.server.nginx {
    environment.systemPackages = with pkgs; [
      lego
    ];

    # users.users.acme = {};

    sops = {
      # secrets.dnstokenfull = { owner = "acme"; };
      secrets.dnstokenfull = { };
      templates."certs.secret".content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder.dnstokenfull}
      '';
    };

    security.acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        email = "mrswarsel@gmail.com";
        dnsProvider = "cloudflare";
        environmentFile = "${config.sops.templates."certs.secret".path}";
      };
    };

    services.nginx = {
      enable = true;
      statusPage = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      # virtualHosts are defined in the respective sections
    };
  };
}
