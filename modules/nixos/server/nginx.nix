{ pkgs, lib, config, ... }:
let
  inherit (config.repo.secrets.common) dnsProvider;
  inherit (config.repo.secrets.common.mail) address3;
in
{
  options.swarselsystems.modules.server.nginx = lib.mkEnableOption "enable nginx on server";
  config = lib.mkIf config.swarselsystems.modules.server.nginx {
    environment.systemPackages = with pkgs; [
      lego
    ];

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
        inherit dnsProvider;
        email = address3;
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
