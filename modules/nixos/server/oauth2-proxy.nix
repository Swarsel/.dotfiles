{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "oauth2-proxy"; port = 3004; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied homeProxy webProxy dnsServer homeProxyIf webProxyIf homeWebProxy oauthServer nginxAccessRules;

  kanidmDomain = globals.services.kanidm.domain;
  mainDomain = globals.domains.main;

  inherit (config.swarselsystems) sopsFile;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
    # largely based on https://github.com/oddlama/nix-config/blob/main/modules/oauth2-proxy.nix
    services.nginx.virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            options.oauth2 = {
              enable = lib.mkEnableOption "access protection of this virtualHost using oauth2-proxy.";
              allowedGroups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  A list of kanidm groups that are allowed to access this resource, or the
                  empty list to allow any authenticated client.
                '';
              };
              X-User = lib.mkOption {
                type = lib.types.str;
                default = "$upstream_http_x_auth_request_user";
                description = "The variable to set as X-User";
              };
              X-Email = lib.mkOption {
                type = lib.types.str;
                default = "$upstream_http_x_auth_request_email";
                description = "The variable to set as X-Email";
              };
              X-Access-Token = lib.mkOption {
                type = lib.types.str;
                default = "$upstream_http_x_auth_request_access_token";
                description = "The variable to set as X-Access-Token";
              };
            };
            options.locations = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule (locationSubmodule: {
                  options = {
                    setOauth2Headers = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Whether to add oauth2 headers to this location. Only takes effect is oauth2 is actually enabled on the parent vhost.";
                    };
                    bypassAuth = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Whether to set auth_request off for this location. Only takes effect is oauth2 is actually enabled on the parent vhost.";
                    };
                  };
                  config = lib.mkIf config.oauth2.enable {
                    extraConfig = lib.optionalString locationSubmodule.config.setOauth2Headers ''
                      proxy_set_header X-User         $user;
                      proxy_set_header Remote-User    $user;
                      proxy_set_header X-Remote-User  $user;
                      proxy_set_header X-Email        $email;
                      # proxy_set_header X-Access-Token $token;
                      add_header Set-Cookie           $auth_cookie;
                    '' + lib.optionalString locationSubmodule.config.bypassAuth ''
                      auth_request off;
                    '';
                  };
                })
              );
            };
            config = lib.mkIf config.oauth2.enable {
              extraConfig = ''
                auth_request /oauth2/auth;
                error_page 401 = /oauth2/sign_in;

                # set variables that can be used in locations.<name>.extraConfig
                # pass information via X-User and X-Email headers to backend,
                # requires running with --set-xauthrequest flag
                auth_request_set $user  ${config.oauth2.X-User};
                auth_request_set $email ${config.oauth2.X-Email};
                # if you enabled --pass-access-token, this will pass the token to the backend
                # auth_request_set $token ${config.oauth2.X-Access-Token};
                # if you enabled --cookie-refresh, this is needed for it to work with auth_request
                auth_request_set $auth_cookie $upstream_http_set_cookie;
              '';
              locations = {
                "/oauth2/" = {
                  proxyPass = "http://oauth2-proxy";
                  setOauth2Headers = false;
                  bypassAuth = true;
                  extraConfig = ''
                    proxy_set_header X-Scheme                $scheme;
                    proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
                  '';
                };
                "= /oauth2/auth" = {
                  proxyPass = "http://oauth2-proxy/oauth2/auth" + lib.optionalString (config.oauth2.allowedGroups != [ ]) "?allowed_groups=${lib.concatStringsSep "," config.oauth2.allowedGroups}";
                  setOauth2Headers = false;
                  bypassAuth = true;
                  extraConfig = ''
                    internal;

                    proxy_set_header X-Scheme       $scheme;
                    # nginx auth_request includes headers but not body
                    proxy_set_header Content-Length "";
                    proxy_pass_request_body         off;
                  '';
                };
              };
            };
          }
        )
      );
    };
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    sops = {
      secrets = {
        "oauth2-cookie-secret" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-oauth2-proxy-client" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };

      templates = {
        "kanidm-oauth2-proxy-client-env" = {
          content = ''
            OAUTH2_PROXY_CLIENT_SECRET="${config.sops.placeholder.kanidm-oauth2-proxy-client}"
            OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.oauth2-cookie-secret}
          '';
          owner = serviceUser;
          group = serviceGroup;
          mode = "0440";
        };
      };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };

    services = {
      ${serviceName} = {
        enable = true;
        cookie = {
          domain = ".${mainDomain}";
          secure = true;
          expire = "900m";
          secret = null; # set by service EnvironmentFile
        };
        clientSecret = null; # set by service EnvironmentFile
        reverseProxy = true;
        httpAddress = "0.0.0.0:${builtins.toString servicePort}";
        redirectURL = "https://${serviceDomain}/oauth2/callback";
        setXauthrequest = true;
        extraConfig = {
          code-challenge-method = "S256";
          whitelist-domain = ".${mainDomain}";
          set-authorization-header = true;
          pass-access-token = true;
          skip-jwt-bearer-tokens = true;
          upstream = "static://202";
          oidc-issuer-url = "https://${kanidmDomain}/oauth2/openid/oauth2-proxy";
          provider-display-name = "Kanidm";
        };
        provider = "oidc";
        scope = "openid email";
        loginURL = "https://${kanidmDomain}/ui/oauth2";
        redeemURL = "https://${kanidmDomain}/oauth2/token";
        validateURL = "https://${kanidmDomain}/oauth2/openid/oauth2-proxy/userinfo";
        clientID = serviceName;
        email.domains = [ "*" ];
      };
    };

    systemd.services = {
      ${serviceName} = {
        # after = [ "kanidm.service" ];
        serviceConfig = {
          RuntimeDirectory = serviceName;
          RuntimeDirectoryMode = "0750";
          UMask = "007"; # TODO remove once https://github.com/oauth2-proxy/oauth2-proxy/issues/2141 is fixed
          RestartSec = "60"; # Retry every minute
          EnvironmentFile = [
            config.sops.templates.kanidm-oauth2-proxy-client-env.path
          ];
        };
      };
    };

    nodes =
      let
        genNginx = toAddress: extraConfig: {
          upstreams = {
            ${serviceName} = {
              servers = {
                "${toAddress}:${builtins.toString servicePort}" = { };
              };
            };
          };
          virtualHosts = {
            "${serviceDomain}" = {
              useACMEHost = globals.domains.main;

              forceSSL = true;
              acmeRoot = null;
              locations = {
                "/" = {
                  proxyPass = "http://${serviceName}";
                };
              };
              extraConfig = ''
                proxy_set_header X-Scheme                $scheme;
                proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
              '' + lib.optionalString (extraConfig != "") extraConfig;
            };
          };
        };
      in
      {
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = genNginx globals.hosts.${oauthServer}.wanAddress4 nginxAccessRules;
      };
  };
}
