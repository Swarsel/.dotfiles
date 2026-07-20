{
  flake.modules.nixos.kanidm =
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
      certsSopsFile = self + /secrets/repo/certs.yaml;
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "kanidm";
          port = 8300;
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
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;
      inherit (globals.services.alloy.extraConfig) otlpGrpcPort;

      certBase = "/etc/ssl";
      certsDir = "${certBase}/certs";
      privateDir = "${certBase}/private";
      certPathBase = "${certsDir}/${serviceName}.crt";
      certPath =
        if config.swarselsystems.isImpermanence then "/persist${certPathBase}" else "${certPathBase}";
      keyPathBase = "${privateDir}/${serviceName}.key";
      keyPath =
        if config.swarselsystems.isImpermanence then "/persist${keyPathBase}" else "${keyPathBase}";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "kanidm" ];
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
          general.idmServer = config.node.name;
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "true";
            path = "/status";
            scheme = "https";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets = {
          "kanidm-admin-pw" = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
          "kanidm-idm-admin-pw" = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
          "kanidm-self-signed-crt" = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            sopsFile = certsSopsFile;
          };
          "kanidm-self-signed-key" = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            sopsFile = certsSopsFile;
          };
          # "kanidm-freshrss" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        };
        users = {
          users.${serviceUser} = {
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds.kanidm = confLib.mkIds 984;
        };
        services = {
          ${serviceName} = {
            package = pkgs.kanidmWithSecretProvisioning_1_10;
            client = {
              enable = true;
              settings = {
                uri = config.services.kanidm.server.settings.origin;
                verify_ca = true;
                verify_hostnames = true;
              };
            };
            provision = {
              # oauth2 systems config is in the respective modules
              inherit (config.repo.secrets.local) persons;
              enable = true;
              adminPasswordFile = config.sops.secrets.kanidm-admin-pw.path;
              idmAdminPasswordFile = config.sops.secrets.kanidm-idm-admin-pw.path;
            };
            server = {
              enable = true;
              settings = {
                bindaddress = "0.0.0.0:${toString servicePort}";
                domain = serviceDomain;
                origin = "https://${serviceDomain}";
                otel_grpc_url = "http://127.0.0.1:${toString otlpGrpcPort}";
                tls_chain = certPathBase;
                tls_key = keyPathBase;
              };
            };
          };
        };
        environment.persistence = {
          "/persist" = lib.mkIf config.swarselsystems.isImpermanence {
            files = [
              certPathBase
              keyPathBase
            ];
          };

          "/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/${serviceName}";
                group = serviceGroup;
                user = serviceUser;
              }
            ];
          };
        };
        systemd.services = {
          "generateSSLCert-${serviceName}" =
            let
              daysValid = 3650;
              renewBeforeDays = 365;
            in
            {
              after = [ "local-fs.target" ];
              before = [ "${serviceName}.service" ];
              requiredBy = [ "${serviceName}.service" ];
              requires = [ "local-fs.target" ];
              script = ''
                      set -eu

                ${pkgs.coreutils}/bin/install -d -m 0755 ${certsDir}
                ${
                  if config.swarselsystems.isImpermanence then
                    "${pkgs.coreutils}/bin/install -d -m 0755 /persist${certsDir}"
                  else
                    ""
                }
                ${pkgs.coreutils}/bin/install -d -m 0755 ${privateDir}
                ${
                  if config.swarselsystems.isImpermanence then
                    "${pkgs.coreutils}/bin/install -d -m 0750 /persist${privateDir}"
                  else
                    ""
                }

                need_gen=0
                if [ ! -f "${certPath}" ] || [ ! -f "${keyPath}" ]; then
                  need_gen=1
                else
                  enddate="$(${pkgs.openssl}/bin/openssl x509 -noout -enddate -in "${certPath}" | cut -d= -f2)"
                  end_epoch="$(${pkgs.coreutils}/bin/date -d "$enddate" +%s)"
                  now_epoch="$(${pkgs.coreutils}/bin/date +%s)"
                  seconds_left=$(( end_epoch - now_epoch ))
                  days_left=$(( seconds_left / 86400 ))
                  if [ "$days_left" -lt ${toString renewBeforeDays} ]; then
                    need_gen=1
                  else
                    echo 'Certificate exists and is still valid'
                  fi
                fi

                if [ "$need_gen" -eq 1 ]; then
                  ${pkgs.openssl}/bin/openssl req -x509 -nodes -days ${toString daysValid} -newkey rsa:4096 -sha256 \
                    -keyout "${keyPath}" \
                    -out "${certPath}" \
                    -subj "/CN=${serviceDomain}" \
                    -addext "subjectAltName=DNS:${serviceDomain}"

                  chmod 0644 "${certPath}"
                  chmod 0600 "${keyPath}"
                  chown ${serviceUser}:${serviceGroup} "${certPath}" "${keyPath}"
                fi
              '';
              serviceConfig.Type = "oneshot";
            };
          kanidm = {
            environment = {
              KANIDM_TRUST_X_FORWARD_FOR = "true";
              OTEL_SERVICE_NAME = "kanidm-${config.node.name}";
            };
            serviceConfig.RestartSec = "30";
          };
        };
        nodes =
          let
            extraConfig = ''
                allow ${globals.networks.home-lan.vlans.services.cidrv4};
              allow ${globals.networks.home-lan.vlans.services.cidrv6};
            '';
          in
          lib.mkMerge [
            {
              ${webProxy}.services.nginx = confLib.genNginx {
                inherit
                  serviceAddress
                  serviceDomain
                  serviceName
                  servicePort
                  ;
                noSslVerify = true;
                protocol = "https";
              };
            }
            {
              ${homeWebProxy}.services.nginx = confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = extraConfig + nginxAccessRules;
                noSslVerify = true;
                protocol = "https";
                serviceAddress = homeServiceAddress;
              };
            }
          ];

      };
    }

  ;
}
