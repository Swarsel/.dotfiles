{
  flake.modules.nixos.nginx =
    { config, lib, ... }:
    let
      serviceUser = "nginx";
      serviceGroup = serviceUser;
    in
    {
      options.services.nginx = {
        recommendedSecurityHeaders = lib.mkEnableOption "additional security headers by default in each location block.";
        virtualHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (_: {
              options = {
                locations = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.submodule (submod: {
                      options = {
                        X-Frame-Options = lib.mkOption {
                          default = "DENY";
                          description = "The value to use for X-Frame-Options";
                          type = lib.types.str;
                        };
                        recommendedSecurityHeaders = lib.mkOption {
                          default = config.services.nginx.recommendedSecurityHeaders;
                          description = "Whether to add additional security headers to this location.";
                          type = lib.types.bool;
                        };
                      };
                      config = {
                        extraConfig = lib.mkIf submod.config.recommendedSecurityHeaders (
                          lib.mkBefore ''
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
            })
          );
        };
      };
      config = {
        swarselsystems.enabledServerModules = [ "nginx" ];
        services.nginx = {
          enable = true;
          group = serviceGroup;
          recommendedBrotliSettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedSecurityHeaders = true;
          recommendedTlsSettings = true;
          sslCiphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:!aNULL";
          statusPage = true;
          user = serviceUser;
          virtualHosts.fallback = {
            default = true;
            locations."/".extraConfig = ''
              deny all;
            '';
            rejectSSL = true;
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/cache/nginx";
              group = "nginx";
              user = "nginx";
            }
          ];
        };
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      };
    }

  ;
}
