{ self, inputs, lib, pkgs, config, dns, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "invidious-companion"; port = 8282; }) servicePort serviceName serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.gen { name = "invidious"; }) serviceDomain;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  sopsFile = self + /secrets/general/invidious-companion.yaml;
  companion = pkgs.stdenv.mkDerivation {
    name = "invidious-companion";
    src = inputs.invidious-companion;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.openssl ];
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp invidious_companion $out/bin/invidious_companion
      chmod +x $out/bin/invidious_companion
    '';
  };
in
{

  config = {
    swarselsystems.enabledServerModules = [ "invidious-companion" ];

    sops = {
      secrets = {
        invidious-companion-key = { inherit sopsFile; mode = "0444"; };
      };

      templates = {
        "invidious-companion.env" = {
          content = ''
            SERVER_SECRET_KEY=${config.sops.placeholder.invidious-companion-key}
            HOST=0.0.0.0
          '';
          mode = "0444";
        };
      };
    };

    topology.self.services.${serviceName} = {
      name = "invidious-companion";
      info = "https://${serviceDomain}";
    };

    systemd.services.invidious-companion = {
      description = "Invidious companion service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${companion}/bin/invidious_companion";
        EnvironmentFile = config.sops.templates."invidious-companion.env".path;
        Restart = "on-failure";
        DynamicUser = true;
      };
    };

    programs.nix-ld.enable = true; # invidious-companion runs as an unpatched deno app

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
      dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
    };

    nodes =
      let
        genNginx = toAddress: extraConfig: {
          upstreams = {
            "${serviceName}" = {
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
              inherit extraConfig;
              locations = {
                "/companion" = {
                  proxyPass = "http://${serviceName}";
                  bypassAuth = true;
                };
              };
            };
          };
        };
      in
      {
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = genNginx homeServiceAddress nginxAccessRules;
      };

  };

}
