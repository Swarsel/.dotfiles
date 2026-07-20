{
  flake-file.inputs.invidious-companion = {
    flake = false;
    url = "https://github.com/iv-org/invidious-companion/releases/download/release-master/invidious_companion-x86_64-unknown-linux-gnu.tar.gz";
  };

  flake.modules.nixos.invidious-companion =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? invidious-companion) [
        (
          {
            self,
            inputs,
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
                name = "invidious-companion";
                port = 8282;
              })
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceName
              servicePort
              ;
            inherit (confLib.gen { name = "invidious"; }) serviceDomain;
            inherit (confLib.static)
              homeServiceAddress
              homeWebProxy
              isHome
              nginxAccessRules
              webProxy
              ;

            sopsFile = self + /secrets/general/invidious-companion.yaml;
            companion = pkgs.stdenv.mkDerivation {
              buildInputs = [
                pkgs.stdenv.cc.cc.lib
                pkgs.openssl
              ];
              installPhase = ''
                mkdir -p $out/bin
                cp invidious_companion $out/bin/invidious_companion
                chmod +x $out/bin/invidious_companion
              '';
              name = "invidious-companion";
              nativeBuildInputs = [ pkgs.autoPatchelfHook ];
              phases = [
                "unpackPhase"
                "installPhase"
              ];
              src = inputs.invidious-companion;
            };
          in
          {
            swarselsystems.enabledServerModules = [ "invidious-companion" ];
            topology.self.services.${serviceName} = {
              icon = "services.invidious";
              info = "https://${serviceDomain}/companion";
              name = "invidious-companion";
            };
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
                path = "/healthz";
              };
              networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
            };
            sops = {
              secrets.invidious-companion-key = {
                inherit sopsFile;
                mode = "0444";
              };

              templates."invidious-companion.env" = {
                content = ''
                  SERVER_SECRET_KEY=${config.sops.placeholder.invidious-companion-key}
                  HOST=0.0.0.0
                '';
                mode = "0444";
              };
            };
            programs.nix-ld.enable = true; # invidious-companion runs as an unpatched deno app
            systemd.services.invidious-companion = {
              after = [ "network.target" ];
              description = "Invidious companion service";
              serviceConfig = {
                DynamicUser = true;
                EnvironmentFile = config.sops.templates."invidious-companion.env".path;
                ExecStart = "${companion}/bin/invidious_companion";
                Restart = "on-failure";
              };
              wantedBy = [ "multi-user.target" ];
            };
            nodes =
              let
                genNginx = toAddress: extraConfig: {
                  upstreams = {
                    "${serviceName}".servers = {
                      "${toAddress}:${builtins.toString servicePort}" = { };
                    };
                  };
                  virtualHosts = {
                    "${serviceDomain}" = {
                      inherit extraConfig;
                      acmeRoot = null;
                      forceSSL = true;
                      locations."/companion" = {
                        bypassAuth = true;
                        proxyPass = "http://${serviceName}";
                      };
                      useACMEHost = globals.domains.main;
                    };
                  };
                };
                homeInvidiousFallback = lib.optionalAttrs (!globals.services.invidious.isHome) {
                  virtualHosts.${serviceDomain}.locations."/" = {
                    extraConfig = ''
                      proxy_ssl_server_name on;
                      proxy_ssl_name ${serviceDomain};
                    '';
                    proxyPass = "https://${globals.services.invidious.proxyAddress4}";
                  };
                };
              in
              lib.mkMerge [
                { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
                {
                  ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                    lib.recursiveUpdate (genNginx homeServiceAddress nginxAccessRules) homeInvidiousFallback
                  );
                }
              ];
          }
        )
      ];
    };
}
