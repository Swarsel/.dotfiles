{ pkgs, lib, config, ... }:
let
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
    defaultStapling = lib.mkEnableOption "add ssl stapling in each location block..";
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (topmod: {
          options = {
            defaultStapling = lib.mkOption {
              type = lib.types.bool;
              default = config.services.nginx.defaultStapling;
              description = "Whether to add ssl stapling to this location.";
            };
            locations = lib.mkOption {
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

                  config = {
                    extraConfig = lib.mkIf submod.config.recommendedSecurityHeaders (lib.mkBefore ''
                      # Hide upstream's versions
                      proxy_hide_header Strict-Transport-Security;
                      proxy_hide_header Referrer-Policy;
                      proxy_hide_header X-Content-Type-Options;
                      proxy_hide_header X-Frame-Options;

                      # Enable HTTP Strict Transport Security (HSTS)
                      add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

                      # Minimize information leaked to other domains
                      add_header Referrer-Policy "origin-when-cross-origin";

                      add_header X-XSS-Protection "1; mode=block";
                      add_header X-Frame-Options "${submod.config.X-Frame-Options}";
                      add_header X-Content-Type-Options "nosniff";
                    ''
                    );
                  };
                })
              );
            };
          };
          config = {
            extraConfig = lib.mkIf topmod.config.defaultStapling (lib.mkBefore ''
              ssl_stapling on;
              ssl_stapling_verify on;
              resolver 1.1.1.1 8.8.8.8 valid=300s;
              resolver_timeout 5s;
            '');
          };
        })
      );
    };
  };
  config = lib.mkIf config.swarselmodules.server.nginx {

    swarselmodules.server.acme = lib.mkDefault true;

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    environment.persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
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
      defaultStapling = true;
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
