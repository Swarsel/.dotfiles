{ lib, globals, confLib, pkgs, ... }:
let
  inherit (confLib.gen { name = "blackbox"; port = 9115; })
    servicePort serviceName;

  mkHttpModule = cfg: {
    prober = "http";
    timeout = "10s";
    http = {
      method = "GET";
      follow_redirects = true;
      preferred_ip_protocol = "ip4";
      tls_config.insecure_skip_verify = true;
      valid_status_codes = [ cfg.expectedStatus ];
    }
    // lib.optionalAttrs (cfg.expectedBodyRegex != null) {
      fail_if_body_not_matches_regexp = [ cfg.expectedBodyRegex ];
    }
    // lib.optionalAttrs (cfg.failIfBodyMatchesRegex != null) {
      fail_if_body_matches_regexp = [ cfg.failIfBodyMatchesRegex ];
    }
    // lib.optionalAttrs (cfg.hostHeader != null) {
      headers.Host = cfg.hostHeader;
    };
  };

  blackboxConfig = pkgs.writeText "blackbox.yml" (builtins.toJSON {
    modules = {
      icmp = {
        prober = "icmp";
        timeout = "5s";
        icmp.preferred_ip_protocol = "ip4";
      };
    } // lib.mapAttrs' (name: cfg: lib.nameValuePair "http_${name}" (mkHttpModule cfg)) globals.monitoring.http;
  });
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    globals.services.${serviceName}.extraConfig.port = servicePort;

    services.prometheus.exporters.blackbox = {
      enable = true;
      port = servicePort;
      listenAddress = "127.0.0.1";
      configFile = blackboxConfig;
    };
  };
}
