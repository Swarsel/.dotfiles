# inspired by https://github.com/atropos112/nixos/blob/7fef652006a1c939f4caf9c8a0cb0892d9cdfe21/modules/garage.nix
{ lib, pkgs, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen {
    name = "garage";
    port = 3900;
    domain = config.repo.secrets.common.services.domains."garage-${config.node.name}";
  }) servicePort serviceName specificServiceName serviceDomain subDomain baseDomain serviceAddress proxyAddress4 proxyAddress6 isHome isProxied homeProxy webProxy dnsServer homeProxyIf webProxyIf;

  cfg = lib.recursiveUpdate config.services.${serviceName} config.swarselsystems.server.${serviceName};
  inherit (config.swarselsystems) sopsFile mainUser;

  # needs SSD
  metadata_dir = "/var/lib/garage/meta";
  # metadata_dir = if config.swarselsystems.isCloud then "/var/lib/garage/meta" else "/Vault/data/garage/meta";

  garageRpcPort = 3901;
  garageWebPort = 3902;
  garageAdminPort = 3903;
  garageK2VPort = 3904;

  adminDomain = "${subDomain}-admin.${baseDomain}";
  webDomain = "${subDomain}-web.${baseDomain}";
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
    swarselsystems.server.${serviceName} = {
      data_dir = {
        path = lib.mkOption {
          type = lib.types.str;
          description = "Directory where Garage stores its metadata";
        };
        capacity = lib.mkOption {
          type = lib.types.str;
        };
      };
      buckets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of buckets to create";
      };
      keys = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        description = "Keys and their associated buckets. Each key gets full access (read/write/owner) to its listed buckets.";
        example = {
          my_key_name = [ "bucket1" "bucket2" ];
          my_other_key = [ "bucket2" "bucket3" ];
        };
      };
    };
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    assertions = [
      {
        assertion = config.swarselsystems.server.${serviceName}.buckets != [ ];
        message = "If Garage is enabled, at least one bucket must be specified in swarselsystems.server.${serviceName}.buckets";
      }
      {
        assertion = builtins.length (lib.attrsToList config.swarselsystems.server.${serviceName}.keys) > 0;
        message = "If Garage is enabled, at least one key must be specified in swarselsystems.server.${serviceName}.keys";
      }
      {
        assertion =
          let
            allKeyBuckets = lib.flatten (lib.attrValues config.swarselsystems.server.${serviceName}.keys);
            invalidBuckets = builtins.filter (bucket: !(lib.elem bucket config.swarselsystems.server.${serviceName}.buckets)) allKeyBuckets;
          in
          invalidBuckets == [ ];
        message = "All buckets referenced in keys must exist in the buckets list";
      }
    ];

    # networking.firewall.allowedTCPPorts = [ servicePort 3901 3902 3903 3904 ];

    nodes.${dnsServer}.swarselsystems.server.dns.${baseDomain}.subdomainRecords = {
      "${subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      "${subDomain}-admin" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      "${subDomain}-web" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      "*.${subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      "*.${subDomain}-web" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    sops = {
      secrets.garage-admin-token = { inherit sopsFile; };
      secrets.garage-rpc-secret = { inherit sopsFile; };
    };

    # DynamicUser cannot read above secrets
    systemd.services.${serviceName}.serviceConfig = {
      DynamicUser = false;
      ProtectHome = lib.mkForce false;
    };

    environment = {
      persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
        { directory = "/var/lib/garage"; }
        (lib.mkIf config.swarselsystems.isCloud { directory = config.swarselsystems.server.${serviceName}.data_dir.path; })
      ];
      systemPackages = [
        cfg.package
      ];
    };

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort 3901 3902 3903 3904 ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeProxy}.allowedTCPPorts = [ servicePort 3901 3902 3903 3904 ];
        };
      };
      services.${specificServiceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };


    services.${serviceName} = {
      enable = true;
      package = pkgs.garage_2;
      settings = {
        data_dir = [ config.swarselsystems.server.${serviceName}.data_dir ];
        inherit metadata_dir;
        db_engine = "lmdb";
        block_size = "128M";
        use_local_tz = false;
        disable_scrub = true;
        replication_factor = 1;
        compression_level = "none";

        rpc_bind_addr = "[::]:${builtins.toString garageRpcPort}";
        # we are not joining our nodes, just use the private ipv4
        rpc_public_addr = "${globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4}:${builtins.toString garageRpcPort}";

        rpc_secret_file = config.sops.secrets.garage-rpc-secret.path;

        s3_api = {
          s3_region = mainUser;
          api_bind_addr = "[::]:${builtins.toString servicePort}";
          root_domain = ".${serviceDomain}";
        };

        s3_web = {
          bind_addr = "[::]:${builtins.toString garageWebPort}";
          root_domain = ".${config.repo.secrets.common.services.domains."garage-web-${config.node.name}"}";
          add_host_to_metrics = true;
        };

        admin = {
          api_bind_addr = "[::]:${builtins.toString garageAdminPort}";
          admin_token_file = config.sops.secrets.garage-admin-token.path;
        };

        k2v_api = {
          api_bind_addr = "[::]:${builtins.toString garageK2VPort}";
        };
      };
    };


    systemd.services = {
      garage-buckets = {
        description = "Create Garage buckets";
        after = [ "garage.service" ];
        wants = [ "garage.service" ];
        wantedBy = [ "multi-user.target" ];

        path = [ cfg.package pkgs.gawk pkgs.coreutils ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "root";
          Group = "root";
        };

        script = ''
          garage status

          # Checking repeatedly with garage status until getting 0 exit code
          while ! garage status >/dev/null 2>&1; do
            echo "Garage not yet operational, waiting..."
            echo "Current garage status output:"
            garage status 2>&1 || true
            echo "---"
            sleep 5
          done

          # Now we check if garage status shows any failed nodes by checking for ==== FAILED NODES ====
          while garage status | grep -q "==== FAILED NODES ===="; do
            echo "Garage has failed nodes, waiting..."
            echo "Current garage status output:"
            garage status 2>&1 || true
            echo "---"
            sleep 5
          done

          echo "Garage is operational, proceeding with bucket management."

          # Get list of existing buckets
          existing_buckets=$(garage bucket list | tail -n +2 | awk '{print $3}' | grep -v '^$' || true)

          # Create buckets that should exist
          ${lib.concatMapStringsSep "\n" (bucket: ''
              if [[ "$(garage bucket info ${lib.escapeShellArg bucket} 2>&1 >/dev/null)" == *"Bucket not found"* ]]; then
                echo "Creating bucket ${lib.escapeShellArg bucket}"
                garage bucket create ${lib.escapeShellArg bucket}
              else
                echo "Bucket ${lib.escapeShellArg bucket} already exists"
              fi
            '')
            cfg.buckets}

          # Remove buckets that shouldn't exist
          for bucket in $existing_buckets; do
            should_exist=false
            ${lib.concatMapStringsSep "\n" (bucket: ''
              if [[ "$bucket" == ${lib.escapeShellArg bucket} ]]; then
                should_exist=true
              fi
            '')
            cfg.buckets}

            if [[ "$should_exist" == "false" ]]; then
              echo "Removing bucket $bucket"
              garage bucket delete --yes "$bucket"
            fi
          done
        '';
      };

      garage-keys = {
        description = "Create Garage keys and set permissions";
        after = [ "garage-buckets.service" ];
        wants = [ "garage-buckets.service" ];
        requires = [ "garage-buckets.service" ];
        wantedBy = [ "multi-user.target" ];

        path = [ cfg.package pkgs.gawk pkgs.coreutils ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "root";
          Group = "root";
        };

        script = ''
          garage key list
          echo "Managing keys..."

          # Get list of existing keys
          existing_keys=$(garage key list | tail -n +2 | awk '{print $3}' | grep -v '^$' || true)

          # Create keys that should exist
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (keyName: _: ''
              if [[ "$(garage key info ${lib.escapeShellArg keyName} 2>&1)" == *"0 matching keys"* ]]; then
                echo "Creating key ${lib.escapeShellArg keyName}"
                garage key create ${lib.escapeShellArg keyName}
              else
                echo "Key ${lib.escapeShellArg keyName} already exists"
              fi
            '')
            cfg.keys)}

          # Set up key permissions for buckets
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (
              keyName: buckets:
                lib.concatMapStringsSep "\n" (bucket: ''
                  echo "Granting full access to key ${lib.escapeShellArg keyName} for bucket ${lib.escapeShellArg bucket}"
                  garage bucket allow --read --write --owner --key ${lib.escapeShellArg keyName} ${lib.escapeShellArg bucket}
                '')
                buckets
            )
            cfg.keys)}

          # Remove permissions from buckets that are no longer associated with keys
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (keyName: buckets: ''
              # Get current buckets this key has access to
              current_buckets=$(garage key info ${lib.escapeShellArg keyName} | grep -A 1000 "==== BUCKETS FOR THIS KEY ====" | tail -n +3 | awk '{print $3}' | grep -v '^$' || true)

              # Remove access from buckets not in the desired list
              for current_bucket in $current_buckets; do
                should_have_access=false
                ${lib.concatMapStringsSep "\n" (bucket: ''
                  if [[ "$current_bucket" == ${lib.escapeShellArg bucket} ]]; then
                    should_have_access=true
                  fi
                '')
                buckets}

                if [[ "$should_have_access" == "false" ]]; then
                  echo "Removing access for key ${lib.escapeShellArg keyName} from bucket $current_bucket"
                  garage bucket deny --key ${lib.escapeShellArg keyName} $current_bucket
                fi
              done
            '')
            cfg.keys)}

          # Remove keys that shouldn't exist
          for key in $existing_keys; do
            should_exist=false
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (keyName: _: ''
              if [[ "$key" == ${lib.escapeShellArg keyName} ]]; then
                should_exist=true
              fi
            '')
            cfg.keys)}

            if [[ "$should_exist" == "false" ]]; then
              echo "Removing key $key"
              garage key delete --yes "$key"
            fi
          done
        '';
      };
    };

    nodes.${webProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
        "${serviceName}Web" = {
          servers = {
            "${serviceAddress}:${builtins.toString garageWebPort}" = { };
          };
        };
        "${serviceName}Admin" = {
          servers = {
            "${serviceAddress}:${builtins.toString garageAdminPort}" = { };
          };
        };
      };
      virtualHosts = {
        "${adminDomain}" = {
          useACMEHost = globals.domains.main;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}Admin";
            };
          };
        };
        "*.${webDomain}" = {
          useACMEHost = globals.domains.main;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}Web";
            };
          };
        };
        "${serviceDomain}" = {
          serverAliases = [ "*.${serviceDomain}" ];
          useACMEHost = globals.domains.main;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 0;
                client_body_timeout        600s;
                proxy_connect_timeout      600s;
                proxy_send_timeout         600s;
                proxy_read_timeout         600s;
                proxy_request_buffering    off;
              '';
            };
          };
        };
      };
    };

  };
}
