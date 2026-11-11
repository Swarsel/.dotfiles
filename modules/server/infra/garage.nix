{
  flake.modules.nixos.garage =
    # inspired by https://github.com/atropos112/nixos/blob/7fef652006a1c939f4caf9c8a0cb0892d9cdfe21/modules/garage.nix
    {
      root,
      config,
      lib,
      pkgs,
      confLib,
      dns,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          domain = config.repo.secrets.common.services.domains."garage-${config.node.name}";
          name = "garage";
          port = 3900;
        })
        baseDomain
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        specificServiceName
        subDomain
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;

      cfg = config.swarselsystems.server.${serviceName};
      inherit (config.services.${serviceName}) package;
      inherit (config.swarselsystems) mainUser;

      garageRpcPort = 3901;
      garageWebPort = 3902;
      garageAdminPort = 3903;
      garageK2VPort = 3904;

      adminDomain = "${subDomain}-admin.${baseDomain}";
      webDomain = "${subDomain}-web.${baseDomain}";
    in
    {
      options = {
        swarselsystems.server.${serviceName} = {
          buckets = lib.mkOption {
            description = "List of buckets to create";
            type = lib.types.listOf lib.types.str;
          };
          data_dir = {
            capacity = lib.mkOption {
              type = lib.types.str;
            };
            path = lib.mkOption {
              description = "Directory where Garage stores its data blocks";
              type = lib.types.str;
            };
          };
          keys = lib.mkOption {
            default = { };
            description = "Keys and their associated buckets. Each key gets full access (read/write/owner) to its listed buckets.";
            example = {
              my_key_name = [
                "bucket1"
                "bucket2"
              ];
              my_other_key = [
                "bucket2"
                "bucket3"
              ];
            };
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          };
        };
      };
      config = {
        swarselsystems.enabledServerModules = [ "garage" ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = lib.swarselsystems.toCapitalized serviceName;
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
              ;
            serviceName = specificServiceName;
          };
          dns.${baseDomain}.subdomainRecords = {
            "${subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
            "${subDomain}-admin" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
            "${subDomain}-web" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
            "*.${subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
            "*.${subDomain}-web" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
          };
          monitoring.http = confLib.mkHttpMonitoring {
            expectedBodyRegex = "fully operational";
            path = "/health";
            serviceName = specificServiceName;
            servicePort = garageAdminPort;
          };
          networks = confLib.mkDualFirewallRules {
            tcpPorts = [
              servicePort
              garageRpcPort
              garageWebPort
              garageAdminPort
              garageK2VPort
            ];
          };
        };
        sops.secrets = {
          garage-admin-token.rekey.generator.script = "base64";
          garage-rpc-secret.rekey.generator = {
            args.length = 32;
            script = "hex";
          };
        };
        services.${serviceName} = {
          enable = true;
          package = pkgs.garage_2;
          settings = {
            admin = {
              admin_token_file = config.sops.secrets.garage-admin-token.path;
              api_bind_addr = "[::]:${builtins.toString garageAdminPort}";
            };
            block_size = "128M";
            compression_level = "none";
            data_dir = [ cfg.data_dir ];
            db_engine = "lmdb";
            disable_scrub = true;
            k2v_api.api_bind_addr = "[::]:${builtins.toString garageK2VPort}";
            # needs SSD
            metadata_dir = "/var/lib/garage/meta";
            replication_factor = 1;
            rpc_bind_addr = "[::]:${builtins.toString garageRpcPort}";
            # we are not joining our nodes, just use the private ipv4
            rpc_public_addr = "${
              globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4
            }:${builtins.toString garageRpcPort}";
            rpc_secret_file = config.sops.secrets.garage-rpc-secret.path;
            s3_api = {
              api_bind_addr = "[::]:${builtins.toString servicePort}";
              root_domain = ".${serviceDomain}";
              s3_region = mainUser;
            };
            s3_web = {
              add_host_to_metrics = true;
              bind_addr = "[::]:${builtins.toString garageWebPort}";
              root_domain = ".${config.repo.secrets.common.services.domains."garage-web-${config.node.name}"}";
            };
            use_local_tz = false;
          };
        };
        assertions = [
          {
            assertion = cfg.buckets != [ ];
            message = "If Garage is enabled, at least one bucket must be specified in swarselsystems.server.${serviceName}.buckets";
          }
          {
            assertion = cfg.keys != { };
            message = "If Garage is enabled, at least one key must be specified in swarselsystems.server.${serviceName}.keys";
          }
          {
            assertion = lib.all (bucket: lib.elem bucket cfg.buckets) (lib.flatten (lib.attrValues cfg.keys));
            message = "All buckets referenced in keys must exist in the buckets list";
          }
        ];
        environment = {
          persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
            { directory = "/var/lib/garage"; }
            (lib.mkIf config.swarselsystems.isCloud {
              directory = cfg.data_dir.path;
            })
          ];
          systemPackages = [ package ];
        };
        systemd = {
          services = {
            garage-buckets = {
              after = [ "garage.service" ];
              description = "Create Garage buckets";
              path = [
                package
                pkgs.gawk
                pkgs.coreutils
              ];
              script = ''
                while ! garage status >/dev/null 2>&1; do
                  sleep 5
                done

                while garage status | grep -q "==== FAILED NODES ===="; do
                  sleep 5
                done

                existing_buckets=$(garage bucket list | tail -n +2 | awk '{print $3}' | grep -v '^$' || true)

                ${lib.concatMapStringsSep "\n" (bucket: ''
                  if [[ "$(garage bucket info ${lib.escapeShellArg bucket} 2>&1 >/dev/null)" == *"Bucket not found"* ]]; then
                    echo "Creating bucket ${lib.escapeShellArg bucket}"
                    garage bucket create ${lib.escapeShellArg bucket}
                  fi
                '') cfg.buckets}

                for bucket in $existing_buckets; do
                  should_exist=false
                  ${lib.concatMapStringsSep "\n" (bucket: ''
                    if [[ "$bucket" == ${lib.escapeShellArg bucket} ]]; then
                      should_exist=true
                    fi
                  '') cfg.buckets}

                  if [[ "$should_exist" == "false" ]]; then
                    echo "Removing bucket $bucket"
                    garage bucket delete --yes "$bucket"
                  fi
                done
              '';
              serviceConfig = {
                RemainAfterExit = true;
                Type = "oneshot";
              };
              wantedBy = [ "multi-user.target" ];
              wants = [ "garage.service" ];
            };

            garage-keys = {
              after = [ "garage-buckets.service" ];
              description = "Create Garage keys and set permissions";
              path = [
                package
                pkgs.gawk
                pkgs.coreutils
              ];
              requires = [ "garage-buckets.service" ];
              script = ''
                existing_keys=$(garage key list | tail -n +2 | awk '{print $3}' | grep -v '^$' || true)

                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (keyName: _: ''
                    if [[ "$(garage key info ${lib.escapeShellArg keyName} 2>&1)" == *"0 matching keys"* ]]; then
                      echo "Creating key ${lib.escapeShellArg keyName}"
                      garage key create ${lib.escapeShellArg keyName}
                    fi
                  '') cfg.keys
                )}

                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    keyName: buckets:
                    lib.concatMapStringsSep "\n" (bucket: ''
                      garage bucket allow --read --write --owner --key ${lib.escapeShellArg keyName} ${lib.escapeShellArg bucket}
                    '') buckets
                  ) cfg.keys
                )}

                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (keyName: buckets: ''
                    current_buckets=$(garage key info ${lib.escapeShellArg keyName} | grep -A 1000 "==== BUCKETS FOR THIS KEY ====" | tail -n +3 | awk '{print $3}' | grep -v '^$' || true)

                    for current_bucket in $current_buckets; do
                      should_have_access=false
                      ${lib.concatMapStringsSep "\n" (bucket: ''
                        if [[ "$current_bucket" == ${lib.escapeShellArg bucket} ]]; then
                          should_have_access=true
                        fi
                      '') buckets}

                      if [[ "$should_have_access" == "false" ]]; then
                        echo "Removing access for key ${lib.escapeShellArg keyName} from bucket $current_bucket"
                        garage bucket deny --key ${lib.escapeShellArg keyName} $current_bucket
                      fi
                    done
                  '') cfg.keys
                )}

                for key in $existing_keys; do
                  should_exist=false
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (keyName: _: ''
                      if [[ "$key" == ${lib.escapeShellArg keyName} ]]; then
                        should_exist=true
                      fi
                    '') cfg.keys
                  )}

                  if [[ "$should_exist" == "false" ]]; then
                    echo "Removing key $key"
                    garage key delete --yes "$key"
                  fi
                done
              '';
              serviceConfig = {
                RemainAfterExit = true;
                Type = "oneshot";
              };
              wantedBy = [ "multi-user.target" ];
            };
          };
          services.${serviceName}.serviceConfig = {
            # DynamicUser cannot read sops secrets
            DynamicUser = false;
            ProtectHome = lib.mkForce false;
          };
        };
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams = {
                ${serviceName}.servers = {
                  "${toAddress}:${builtins.toString servicePort}" = { };
                };
                "${serviceName}Admin".servers = {
                  "${toAddress}:${builtins.toString garageAdminPort}" = { };
                };
                "${serviceName}Web".servers = {
                  "${toAddress}:${builtins.toString garageWebPort}" = { };
                };
              };
              virtualHosts = {
                "${adminDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations."/".proxyPass = "http://${serviceName}Admin";
                  oauth2.enable = false;
                  useACMEHost = globals.domains.main;
                };
                "${serviceDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations."/" = {
                    extraConfig = ''
                      client_max_body_size 0;
                      client_body_timeout        600s;
                      proxy_connect_timeout      600s;
                      proxy_send_timeout         600s;
                      proxy_read_timeout         600s;
                      proxy_request_buffering    off;
                    '';
                    proxyPass = "http://${serviceName}";
                  };
                  oauth2.enable = false;
                  serverAliases = [ "*.${serviceDomain}" ];
                  useACMEHost = globals.domains.main;
                };
                "*.${webDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations."/".proxyPass = "http://${serviceName}Web";
                  oauth2.enable = false;
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            { ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules); }
          ];

      };
    };
}
