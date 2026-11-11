{
  flake.modules.nixos.bastion =
    {
      root,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      nodes,
      ...
    }:
    let
      homeWan = globals.networks.home-wan;
      jumpTargets = lib.filterAttrs (
        name: host: name != config.node.name && !host.isHome && host.wanAddress4 != null
      ) globals.hosts;
      permitOpen = lib.concatLists (
        lib.mapAttrsToList (
          name: host:
          let
            inherit (nodes.${name}.config) boot services;
          in
          lib.concatMap
            (
              port:
              [ "${host.wanAddress4}:${toString port}" ]
              ++ lib.optional (host.wanAddress6 != null) "[${host.wanAddress6}]:${toString port}"
            )
            (services.openssh.ports ++ lib.optional boot.initrd.network.ssh.enable boot.initrd.network.ssh.port)
        ) jumpTargets
      );
      journalSelector = unit: ''{host="${config.node.name}",unit="${unit}"}'';
      mkJournalAlertRule =
        args:
        confLib.mkGrafanaAlertRule (
          {
            datasourceUid = "loki";
            forDuration = "0s";
            noDataState = "OK";
            op = "gt";
            queryType = "instant";
            threshold = 0;
          }
          // args
        );
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "bastion" ];
        users = {
          users = {
            ${config.swarselsystems.mainUser}.enable = false;
            jump = {
              autoSubUidGidRange = false;
              createHome = lib.mkForce true;
              group = lib.mkForce "jump";
              isNormalUser = true;
              openssh.authorizedKeys.keyFiles = [
                (root "files/public/ssh/yubikey.pub")
                (root "files/public/ssh/magicant.pub")
                (root "files/public/ssh/builder.pub")
              ];
              useDefaultShell = true;
            };
          };
          groups.jump = { };
          persistentIds.jump = confLib.mkIds 1001;
        };
        services.openssh = {
          enable = true;
          authorizedKeysInHomedir = false;
          extraConfig = ''
            Match User jump
              ForceCommand ${lib.getExe' pkgs.coreutils "false"}
              PermitTTY no
              X11Forwarding no
              PermitTunnel no
              GatewayPorts no
              AllowAgentForwarding no
              AllowStreamLocalForwarding no
              AllowTcpForwarding local
              PermitOpen ${lib.concatStringsSep " " permitOpen}
          '';
          hostKeys = lib.mkIf (!(builtins.elem "ssh" config.swarselsystems.enabledServerModules)) [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
          settings = {
            AllowUsers = lib.mkForce (
              [ "jump" ]
              ++ map (cidr: "root@${cidr}") [
                homeWan.cidrv4
                homeWan.cidrv6
              ]
            );
            KbdInteractiveAuthentication = false;
            LogLevel = "VERBOSE";
            LoginGraceTime = 20;
            MaxAuthTries = 3;
            MaxStartups = "10:30:60";
            PasswordAuthentication = false;
          };
          startWhenNeeded = lib.mkForce false;
        };
        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          [
            {
              folder = "Infrastructure";
              interval = "1m";
              name = "bastion-${config.node.name}";
              orgId = 1;
              rules = [
                (mkJournalAlertRule {
                  expr = ''sum(count_over_time(${journalSelector "sshd.service"} |= "Accepted publickey for root" [10m]))'';
                  severity = "warning";
                  summary = "root logged in on ${config.node.name} over ssh";
                  title = "bastion root login (${config.node.name})";
                  uid = "bastion_root_login_${config.node.name}";
                })
                (mkJournalAlertRule {
                  expr = ''sum(count_over_time(${journalSelector "sshd.service"} |= "but the request was denied" [10m]))'';
                  summary = "a jump session on ${config.node.name} requested a forward to a target outside the permitted list";
                  title = "bastion forward denied (${config.node.name})";
                  uid = "bastion_forward_denied_${config.node.name}";
                })
                (mkJournalAlertRule {
                  expr = ''sum(count_over_time(${journalSelector "sshd.service"} |= "Server listening on" [10m])) unless sum(count_over_time(${journalSelector "init.scope"} |= "Reloading..." [20m]))'';
                  summary = "sshd on ${config.node.name} started without a preceding configuration switch";
                  title = "bastion sshd restart outside deploy (${config.node.name})";
                  uid = "bastion_sshd_restart_${config.node.name}";
                })
              ];
            }
          ];
      };
    };
}
