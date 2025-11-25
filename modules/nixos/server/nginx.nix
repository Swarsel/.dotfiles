{ pkgs, lib, config, ... }:
let
  inherit (config.repo.secrets.common) dnsProvider;
  inherit (config.repo.secrets.common.mail) address3;

  serviceUser = "nginx";
  serviceGroup = serviceUser;

  sslBasePath = "/etc/ssl";
  dhParamsPathBase = "${sslBasePath}/dhparams.pem";
  dhParamsPath =
    if config.swarselsystems.isImpermanence then
      "/persist/${dhParamsPathBase}"
    else
      "${dhParamsPathBase}";
in
{
  options.swarselmodules.server.nginx = lib.mkEnableOption "enable nginx on server";
  options.services.nginx = {
    recommendedSecurityHeaders = lib.mkEnableOption "additional security headers by default in each location block.";
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.locations = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (submod: {
                options = {
                  recommendedSecurityHeaders = lib.mkOption {
                    type = lib.types.bool;
                    default = config.services.nginx.recommendedSecurityHeaders;
                    description = "Whether to add additional security headers to this location.";
                  };

                  X-Frame-Options = lib.mkOption {
                    type = lib.types.str;
                    default = "DENY";
                    description = "The value to use for X-Frame-Options";
                  };
                };
                config = lib.mkIf submod.config.recommendedSecurityHeaders {
                  extraConfig = lib.mkBefore ''
                    # Enable HTTP Strict Transport Security (HSTS)
                    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

                    # Minimize information leaked to other domains
                    add_header Referrer-Policy "origin-when-cross-origin";

                    add_header X-XSS-Protection "1; mode=block";
                    add_header X-Frame-Options "${submod.config.X-Frame-Options}";
                    add_header X-Content-Type-Options "nosniff";
                  '';
                };
              })
            );
          };
        }
      );
    };
  };
  config = lib.mkIf config.swarselmodules.server.nginx {
    environment.systemPackages = with pkgs; [
      lego
    ];

    sops = {
      secrets.acme-dns-token = { inherit (config.swarselsystems) sopsFile; };
      templates."certs.secret".content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder.acme-dns-token}
      '';
    };

    users.groups.acme.members = [ "nginx" ];

    security.acme = {
      acceptTerms = true;
      defaults = {
        inherit dnsProvider;
        email = address3;
        environmentFile = "${config.sops.templates."certs.secret".path}";
        reloadServices = [ "nginx" ];
        dnsPropagationCheck = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    environment.persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
      directories = [{ directory = "/var/lib/acme"; }];
      files = [ dhParamsPathBase ];
    };

    services.nginx = {
      enable = true;
      user = serviceUser;
      group = serviceGroup;
      statusPage = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedBrotliSettings = true;
      recommendedSecurityHeaders = true;
      sslCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:!aNULL";
      sslDhparam = dhParamsPathBase;
      virtualHosts.fallback = {
        default = true;
        rejectSSL = true;
        locations."/".extraConfig = ''
          deny all;
        '';
      };
    };
    systemd.services.generateDHParams = {
      before = [ "nginx.service" ];
      requiredBy = [ "nginx.service" ];
      after = [ "local-fs.target" ];
      requires = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
      };

      script = ''
        set -eu

        install -d -m 0755 ${sslBasePath}
        ${if config.swarselsystems.isImpermanence then "${pkgs.coreutils}/bin/install -d -m 0755 /persist${sslBasePath}" else ""}

        if [ ! -f "${dhParamsPath}" ]; then
          ${pkgs.openssl}/bin/openssl dhparam -out "${dhParamsPath}" 4096
          chmod 0644 "${dhParamsPath}"
          chown ${serviceUser}:${serviceGroup} "${dhParamsPath}"
        else
          echo 'Already generated DHParams'
        fi
      '';
    };

    # system.activationScripts."createPersistentStorageDirs" = lib.mkIf config.swarselsystems.isImpermanence {
    #   deps = [ "generateDHParams" "users" "groups" ];
    # };
    # system.activationScripts."generateDHParams" =
    #   {
    #     text = ''
    #       set -eu

    #       ${if config.swarselsystems.isImpermanence then "${pkgs.coreutils}/bin/install -d -m 0755 /persist${sslBasePath}" else "${pkgs.coreutils}/bin/install -d -m 0755 ${sslBasePath}"}

    #       if [ ! -f "${dhParamsPath}" ]; then
    #         ${pkgs.openssl}/bin/openssl dhparam -out ${dhParamsPath} 4096
    #         chmod 0644 ${dhParamsPath}
    #         chown ${serviceUser}:${serviceGroup} ${dhParamsPath}
    #       fi
    #     '';
    #     deps = [
    #       (lib.mkIf config.swarselsystems.isImpermanence "specialfs")
    #       (lib.mkIf (!config.swarselsystems.isImpermanence) "etc")
    #     ];
    #   };
  };
}
