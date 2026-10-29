{
  flake.modules.nixos.restic =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit (config.swarselsystems.server.restic) targets;
      metricsDir = "/var/lib/restic-metrics";
    in
    {
      options.swarselsystems.server.restic.targets = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }: {
              options = {
                bucketName = lib.mkOption {
                  default = name;
                  type = lib.types.str;
                };
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                };
                repository = lib.mkOption {
                  type = lib.types.str;
                };
                withPostgres = lib.mkOption {
                  default = false;
                  type = lib.types.bool;
                };
              };
            }
          )
        );
      };
      config = {
        swarselsystems.enabledServerModules = [ "restic" ];
        sops = {
          secrets = lib.mkMerge (
            lib.mapAttrsToList (name: _: {
              "resticaccesskey-${name}" = { inherit sopsFile; };
              "resticpw-${name}" = { inherit sopsFile; };
              "resticsecretaccesskey-${name}" = { inherit sopsFile; };
            }) targets
          );

          templates = lib.mkMerge (
            lib.mapAttrsToList (name: _: {
              "restic-env-${name}".content = ''
                AWS_ACCESS_KEY_ID=${config.sops.placeholder."resticaccesskey-${name}"}
                AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."resticsecretaccesskey-${name}"}
              '';
            }) targets
          );
        };
        services.restic.backups = lib.mapAttrs' (
          name: target:
          let
            postgresDumpDir = "/var/backup/restic-${name}";
          in
          lib.nameValuePair target.bucketName {
            inherit (target) repository;
            backupPrepareCommand = ''
              set -euo pipefail
            ''
            + lib.optionalString target.withPostgres ''
              ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root ${postgresDumpDir}
              ${pkgs.util-linux}/bin/runuser -u postgres -- ${config.services.postgresql.package}/bin/pg_dumpall --clean --if-exists > ${postgresDumpDir}/dumpall.sql
              ${pkgs.coreutils}/bin/chmod 0600 ${postgresDumpDir}/dumpall.sql
            '';
            environmentFile = config.sops.templates."restic-env-${name}".path;
            extraBackupArgs = [ "--group-by host" ];
            initialize = true;
            passwordFile = config.sops.secrets."resticpw-${name}".path;
            paths = target.paths ++ lib.optional target.withPostgres postgresDumpDir;
            pruneOpts = [
              "--group-by host"
              "--keep-daily 3"
              "--keep-weekly 2"
              "--keep-monthly 3"
              "--keep-yearly 5"
            ];
            timerConfig.OnCalendar = "03:00";
          }
        ) targets;
        environment = {
          etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
            lib.mkAfter ''
              prometheus.exporter.unix "restic" {
                set_collectors = ["textfile"]

                textfile {
                  directory = "${metricsDir}"
                }
              }

              prometheus.scrape "restic" {
                targets    = prometheus.exporter.unix.restic.targets
                forward_to = [prometheus.remote_write.mimir.receiver]
                job_name   = "restic"
              }
            ''
          );
          persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
            {
              directory = metricsDir;
              mode = "0755";
            }
          ];
        };
        systemd = {
          services = lib.mapAttrs' (
            _: target:
            lib.nameValuePair "restic-backups-${target.bucketName}" {
              postStart = ''
                ${pkgs.coreutils}/bin/echo "restic_backup_last_success_timestamp_seconds{target=\"${target.bucketName}\"} $(${pkgs.coreutils}/bin/date +%s)" > ${metricsDir}/${target.bucketName}.prom.tmp
                ${pkgs.coreutils}/bin/mv ${metricsDir}/${target.bucketName}.prom.tmp ${metricsDir}/${target.bucketName}.prom
              '';
            }
          ) targets;
          tmpfiles.settings."10-restic-metrics".${metricsDir}.d.mode = "0755";
        };
        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          lib.optional (targets != { }) {
            folder = "Infrastructure";
            interval = "1m";
            name = "restic-${config.node.name}";
            orgId = 1;
            rules = lib.mapAttrsToList (
              _: target:
              let
                staleAfter = 26 * 3600;
              in
              confLib.mkGrafanaAlertRule {
                expr = ''time() - max(restic_backup_last_success_timestamp_seconds{host="${config.node.name}",target="${target.bucketName}"}) or vector(${toString (staleAfter + 1)})'';
                forDuration = "30m";
                op = "gt";
                summary = "restic backup ${target.bucketName} on ${config.node.name} has not succeeded in the last 26 hours";
                threshold = staleAfter;
                title = "restic backup stale (${config.node.name}/${target.bucketName})";
                uid = "restic_stale_${target.bucketName}";
              }
            ) targets;
          };
      };
    }

  ;
}
