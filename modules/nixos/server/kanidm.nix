{ self, lib, pkgs, config, globals, dns, confLib, ... }:
let
  certsSopsFile = self + /secrets/repo/certs.yaml;
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "kanidm"; port = 8300; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf dnsServer homeServiceAddress nginxAccessRules;

  certBase = "/etc/ssl";
  certsDir = "${certBase}/certs";
  privateDir = "${certBase}/private";
  certPathBase = "${certsDir}/${serviceName}.crt";
  certPath =
    if config.swarselsystems.isImpermanence then
      "/persist${certPathBase}"
    else
      "${certPathBase}";
  keyPathBase = "${privateDir}/${serviceName}.key";
  keyPath =
    if config.swarselsystems.isImpermanence then
      "/persist${keyPathBase}"
    else
      "${keyPathBase}";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {


    users = {
      persistentIds = {
        kanidm = confLib.mkIds 984;
      };
      users.${serviceUser} = {
        group = serviceGroup;
        isSystemUser = true;
      };

      groups.${serviceGroup} = { };
    };

    sops = {
      secrets = {
        "kanidm-self-signed-crt" = { sopsFile = certsSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-self-signed-key" = { sopsFile = certsSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-admin-pw" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-idm-admin-pw" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        # "kanidm-freshrss" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    globals = {
      general.idmServer = config.node.name;
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
    };

    environment.persistence = {
      "/persist" = lib.mkIf config.swarselsystems.isImpermanence {
        files = [
          certPathBase
          keyPathBase
        ];
      };

      "/state" = lib.mkIf config.swarselsystems.isMicroVM {
        directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
      };
    };

    systemd.services = {
      "generateSSLCert-${serviceName}" =
        let
          daysValid = 3650;
          renewBeforeDays = 365;
        in
        {
          before = [ "${serviceName}.service" ];
          requiredBy = [ "${serviceName}.service" ];
          after = [ "local-fs.target" ];
          requires = [ "local-fs.target" ];

          serviceConfig = {
            Type = "oneshot";
          };

          script = ''
                  set -eu

            ${pkgs.coreutils}/bin/install -d -m 0755 ${certsDir}
            ${if config.swarselsystems.isImpermanence then "${pkgs.coreutils}/bin/install -d -m 0755 /persist${certsDir}" else ""}
            ${pkgs.coreutils}/bin/install -d -m 0755 ${privateDir}
            ${if config.swarselsystems.isImpermanence then "${pkgs.coreutils}/bin/install -d -m 0750 /persist${privateDir}" else ""}

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
        };
      kanidm = {
        environment.KANIDM_TRUST_X_FORWARD_FOR = "true";
        serviceConfig.RestartSec = "30";
      };
    };



    services = {
      ${serviceName} = {
        package = pkgs.kanidmWithSecretProvisioning_1_9;
        server = {
          enable = true;
          settings = {
            domain = serviceDomain;
            origin = "https://${serviceDomain}";
            # tls_chain = config.sops.secrets.kanidm-self-signed-crt.path;
            tls_chain = certPathBase;
            # tls_key = config.sops.secrets.kanidm-self-signed-key.path;
            tls_key = keyPathBase;
            bindaddress = "0.0.0.0:${toString servicePort}";
            # trust_x_forward_for = true;
          };
        };
        client = {
          enable = true;
          settings = {
            uri = config.services.kanidm.server.settings.origin;
            verify_ca = true;
            verify_hostnames = true;
          };
        };
        provision = {
          enable = true;
          adminPasswordFile = config.sops.secrets.kanidm-admin-pw.path;
          idmAdminPasswordFile = config.sops.secrets.kanidm-idm-admin-pw.path;

          # oauth2 systems config is in the respective modules

          inherit (config.repo.secrets.local) persons;
        };
      };
    };


    nodes =
      let
        extraConfig = ''
            allow ${globals.networks.home-lan.vlans.services.cidrv4};
          allow ${globals.networks.home-lan.vlans.services.cidrv6};
        '';
      in
      {
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; protocol = "https"; noSslVerify = true; };
        ${homeWebProxy}.services.nginx = confLib.genNginx { inherit servicePort serviceDomain serviceName; protocol = "https"; noSslVerify = true; extraConfig = extraConfig + nginxAccessRules; serviceAddress = homeServiceAddress; };
      };

  };
}
