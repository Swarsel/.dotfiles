{ pkgs, config, ... }:
{
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
    defaults.email = "mrswarsel@gmail.com";
    defaults.dnsProvider = "cloudflare";
    defaults.environmentFile = "${config.sops.templates."certs.secret".path}";
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    # virtualHosts are defined in the respective sections
  };

}
