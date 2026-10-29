{
  flake.modules.nixos.parsedmarc =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/private/opensearch";
          name = "parsedmarc";
        })
        serviceDir
        serviceName
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.name = serviceName;
        globals.monitoring = {
          http = confLib.mkHttpMonitoring {
            expectedBodyRegex = ''"status":"(green|yellow)"'';
            path = "/_cluster/health";
            serviceName = "opensearch";
            servicePort = config.services.opensearch.settings."http.port";
          };
          systemd = confLib.mkSystemdMonitoring {
            inherit serviceName;
            unit = "parsedmarc.service";
          };
        };
        sops.secrets.parsedmarc-imap-password.sopsFile = self + /secrets/general/parsedmarc.yaml;
        services = {
          ${serviceName} = {
            enable = true;
            provision = {
              geoIp = false;
              grafana.dashboard = false;
            };
            settings = {
              general.save_smtp_tls = true;
              imap = {
                host = globals.services.mailserver.domain;
                password._secret = config.sops.secrets.parsedmarc-imap-password.path;
                port = 993;
                ssl = true;
                user = confLib.static.dmarcMailAddress;
              };
            };
          };
          opensearch.extraJavaOptions = [
            "-Xms512m"
            "-Xmx512m"
          ];
        };
        environment.persistence."/state".directories = lib.mkIf config.swarselsystems.isMicroVM [
          {
            directory = serviceDir;
            mode = "0700";
          }
        ];
      };
    }

  ;
}
