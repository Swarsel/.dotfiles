{ self, lib, pkgs, config, configName, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "garage"; port = 3900; }) servicePort serviceName serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  sopsFile = self + /secrets/${configName}/secrets2.yaml;

  cfg = config.services.${serviceName};
  metadata_dir = "/var/lib/garage/meta";
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
    swarselsystems.server.${serviceName} = {
      data_dir = lib.mkOption {
        type = lib.types.either lib.types.path (lib.types.listOf lib.types.attrs);
        default = "/var/lib/garage/data";
      };
    };
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    sops = {
      secrets.garage-admin-token = { inherit sopsFile; };
      secrets.garage-rpc-secret = { inherit sopsFile; };
    };

    environment = {
      persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
        { directory = metadata_dir; }
      ];
      systemPackages = [
        cfg.package
      ];
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    systemd.services.${serviceName}.serviceConfig = {
      DynamicUser = false;
      ProtectHome = lib.mkForce false;
    };

    services.${serviceName} = {
      enable = true;
      package = pkgs.garage_2;
      settings = {
        inherit (config.swarselsystems.${serviceName}) data_dir;
        inherit metadata_dir;
        db_engine = "lmdb";
        block_size = "1MiB";
        use_local_tz = false;

        replication_factor = 2; # Number of copies of data

        rpc_bind_addr = "[::]:3901";
        rpc_public_addr = "${config.repo.secrets.local.ipv4}:4317";
        rpc_secret_file = config.sops.secrets.garage-rpc-secret.path;

        s3_api = {
          s3_region = "swarsel";
          api_bind_addr = "0.0.0.0:${builtins.toString servicePort}";
          root_domain = ".s3.garage.localhost";
        };

        admin = {
          api_bind_addr = "0.0.0.0:3903";
          admin_token_file = config.sops.secrets.garage-admin-token.path;
        };

        k2v_api = {
          api_bind_addr = "[::]:3904";
        };
      };
    };

    nodes.${serviceProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
            };
          };
        };
      };
    };

  };
}
