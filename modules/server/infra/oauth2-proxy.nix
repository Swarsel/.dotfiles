{
  flake.modules.nixos.oauth2-proxy =
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
      inherit
        (confLib.gen {
          name = "oauth2-proxy";
          port = 3004;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeProxy
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        oauthServer
        webProxy
        ;

      mainDomain = globals.domains.main;

      inherit (config.swarselsystems) sopsFile;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";

      homeProxyWan4 = globals.hosts.${homeProxy}.wanAddress4 or null;
      homeProxyWan6 = globals.hosts.${homeProxy}.wanAddress6 or null;
      trustedProxyIPs = [
        "127.0.0.1"
        "::1"
      ]
      ++ lib.optional (homeProxyWan4 != null) homeProxyWan4
      ++ lib.optional (homeProxyWan6 != null) homeProxyWan6;
    in
    {
      options = {
        # largely based on https://github.com/oddlama/nix-config/blob/main/modules/oauth2-proxy.nix
        services.nginx.virtualHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { config, ... }:
              {
                options = {
                  locations = lib.mkOption {
                    type = lib.types.attrsOf (
                      lib.types.submodule (locationSubmodule: {
                        options = {
                          bypassAuth = lib.mkOption {
                            default = false;
                            description = "Whether to set auth_request off for this location. Only takes effect is oauth2 is actually enabled on the parent vhost.";
                            type = lib.types.bool;
                          };
                          setOauth2Headers = lib.mkOption {
                            default = true;
                            description = "Whether to add oauth2 headers to this location. Only takes effect is oauth2 is actually enabled on the parent vhost.";
                            type = lib.types.bool;
                          };
                        };
                        config = lib.mkIf config.oauth2.enable {
                          extraConfig =
                            lib.optionalString locationSubmodule.config.setOauth2Headers ''
                              proxy_set_header X-User         $user;
                                proxy_set_header Remote-User    $user;
                                proxy_set_header X-Remote-User  $user;
                                proxy_set_header X-Email        $email;
                                # proxy_set_header X-Access-Token $token;
                                add_header Set-Cookie           $auth_cookie;
                            ''
                            + lib.optionalString locationSubmodule.config.bypassAuth ''
                              auth_request off;
                            '';
                        };
                      })
                    );
                  };
                  oauth2 = {
                    enable = lib.mkEnableOption "access protection of this virtualHost using oauth2-proxy.";
                    X-Access-Token = lib.mkOption {
                      default = "$upstream_http_x_auth_request_access_token";
                      description = "The variable to set as X-Access-Token";
                      type = lib.types.str;
                    };
                    X-Email = lib.mkOption {
                      default = "$upstream_http_x_auth_request_email";
                      description = "The variable to set as X-Email";
                      type = lib.types.str;
                    };
                    X-User = lib.mkOption {
                      default = "$upstream_http_x_auth_request_user";
                      description = "The variable to set as X-User";
                      type = lib.types.str;
                    };
                    allowedGroups = lib.mkOption {
                      default = [ ];
                      description = ''
                        A list of kanidm groups that are allowed to access this resource, or the
                          empty list to allow any authenticated client.
                      '';
                      type = lib.types.listOf lib.types.str;
                    };
                  };
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
                      bypassAuth = true;
                      extraConfig = ''
                        proxy_set_header X-Scheme                $scheme;
                          proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
                      '';
                      proxyPass = "http://oauth2-proxy";
                      setOauth2Headers = false;
                    };
                    "= /oauth2/auth" = {
                      bypassAuth = true;
                      extraConfig = ''
                        internal;

                          proxy_set_header X-Scheme       $scheme;
                          # nginx auth_request includes headers but not body
                          proxy_set_header Content-Length "";
                          proxy_pass_request_body         off;
                      '';
                      proxyPass =
                        "http://oauth2-proxy/oauth2/auth"
                        + lib.optionalString (
                          config.oauth2.allowedGroups != [ ]
                        ) "?allowed_groups=${lib.concatStringsSep "," config.oauth2.allowedGroups}";
                      setOauth2Headers = false;
                    };
                  };
                };
              }
            )
          );
        };
      };
      config = lib.mkIf (builtins.elem "oauthServer" config.swarselsystems.nodeRoles) {
        swarselsystems.enabledServerModules = [ "oauth2-proxy" ];
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "OK";
            path = "/ready";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            "kanidm-oauth2-proxy" = {
              group = serviceGroup;
              mode = "0440";
              owner = serviceUser;
              sopsFile = kanidmSopsFile;
            };
            "oauth2-cookie-secret" = {
              inherit sopsFile;
              group = serviceGroup;
              mode = "0440";
              owner = serviceUser;
            };
          };

          templates."kanidm-oauth2-proxy-client-env" = {
            content = ''
              OAUTH2_PROXY_CLIENT_SECRET="${config.sops.placeholder.kanidm-oauth2-proxy}"
                OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.oauth2-cookie-secret}
            '';
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
        };
        users.persistentIds.oauth2-proxy = confLib.mkIds 966;
        services = {
          ${serviceName} = {
            enable = true;
            package = pkgs.oauth2-proxy;
            clientID = serviceName;
            clientSecretFile = null;
            cookie = {
              domain = ".${mainDomain}";
              expire = "900m";
              secretFile = null;
              secure = true;
            };
            email.domains = [ "*" ];
            extraConfig = {
              code-challenge-method = "S256";
              oidc-issuer-url = "https://${kanidmDomain}/oauth2/openid/oauth2-proxy";
              pass-access-token = true;
              provider-display-name = "Kanidm";
              set-authorization-header = true;
              skip-jwt-bearer-tokens = true;
              whitelist-domain = ".${mainDomain}";
            };
            httpAddress = "0.0.0.0:${builtins.toString servicePort}";
            loginURL = "https://${kanidmDomain}/ui/oauth2";
            provider = "oidc";
            redeemURL = "https://${kanidmDomain}/oauth2/token";
            redirectURL = "https://${serviceDomain}/oauth2/callback";
            reverseProxy = true;
            scope = "openid email";
            setXauthrequest = true;
            trustedProxyIP = trustedProxyIPs;
            upstream = [
              "static://202"
            ];
            validateURL = "https://${kanidmDomain}/oauth2/openid/oauth2-proxy/userinfo";
          };
        };
        # needed for homeWebProxy
        networking.firewall.allowedTCPPorts = [ servicePort ];
        systemd.services = {
          ${serviceName} = {
            # after = [ "kanidm.service" ];
            serviceConfig = {
              EnvironmentFile = [
                config.sops.templates.kanidm-oauth2-proxy-client-env.path
              ];
              RestartSec = "60"; # Retry every minute
              RuntimeDirectory = serviceName;
              RuntimeDirectoryMode = "0750";
              UMask = "007"; # TODO remove once https://github.com/oauth2-proxy/oauth2-proxy/issues/2141 is fixed
            };
          };
        };
        nodes =
          let
            extraConfig = ''
              proxy_set_header X-Scheme                $scheme;
                proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
                allow ${globals.networks.home-lan.vlans.services.cidrv4};
                allow ${globals.networks.home-lan.vlans.services.cidrv6};
            '';
          in
          lib.mkMerge [
            {
              ${idmServer} = {
                sops.secrets.kanidm-oauth2-proxy = {
                  group = "kanidm";
                  mode = "0440";
                  owner = "kanidm";
                  sopsFile = kanidmSopsFile;
                };
                services.kanidm.provision.systems.oauth2.oauth2-proxy = {
                  basicSecretFile = config.sops.secrets.kanidm-oauth2-proxy.path; # dirty but saves a cross-evaluation
                  claimMaps.groups.joinType = "array";
                  displayName = "Oauth2-Proxy";
                  originLanding = "https://${serviceDomain}/";
                  originUrl = "https://${serviceDomain}/oauth2/callback";
                  preferShortUsername = true;
                };
              };
            }
            {
              ${webProxy}.services.nginx = confLib.genNginx {
                inherit
                  extraConfig
                  serviceAddress
                  serviceDomain
                  serviceName
                  servicePort
                  ;
              };
            }
            {
              ${homeWebProxy}.services.nginx = confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = extraConfig + nginxAccessRules;
                serviceAddress = globals.hosts.${oauthServer}.wanAddress4;
              };
            }
          ];
      };
    }

  ;
}
