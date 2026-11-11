{
  flake.modules.nixos.nfs =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      shareUser = "eternor";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "nfs" ];
        globals.monitoring = {
          tcp = confLib.mkTcpMonitoring {
            serviceName = "samba";
            servicePort = 445;
          };
          systemd = lib.mkMerge [
            (confLib.mkSystemdMonitoring {
              serviceName = "avahi-${config.node.name}";
              unit = "avahi-daemon.service";
            })
            (confLib.mkSystemdMonitoring {
              serviceName = "samba-wsdd";
              unit = "samba-wsdd.service";
            })
          ];
        };
        sops.secrets.samba-user-pw.mode = "0400";
        users = {
          users.${shareUser} = {
            group = "users";
            isSystemUser = true;
          };
          persistentIds = {
            ${shareUser}.uid = 1000;
            avahi = confLib.mkIds 978;
          };
        };
        services = {
          avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
            settings.publish = {
              disable-publishing = false;
              disable-user-service-publishing = false; # Needed to allow samba to automatically register mDNS records without the need for an `extraServiceFile`
              publish-addresses = true;
            };
          };
          samba = {
            enable = true;
            package = pkgs.samba4;
            openFirewall = true;
            settings = {
              Eternor = {
                browseable = "yes";
                comment = "Eternor";
                "create mask" = "0660";
                "directory mask" = "2770";
                "guest ok" = "no";
                path = "/storage";
                "read only" = "no";
                "valid users" = shareUser;
                writable = "true";
              };
              global."username map" =
                "${pkgs.writeText "samba-username-map" "${shareUser} = ${globals.user.name}\n"}";
            };
          };
          # This enables autodiscovery on windows since SMB1 (and thus netbios) support was discontinued
          samba-wsdd = {
            enable = true;
            openFirewall = true;
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            { directory = "/var/cache/samba"; }
            { directory = "/var/lib/samba"; }
          ];
        };
        systemd.services.samba-ensure-user-pw = {
          after = [ "samba-smbd.service" ];
          description = "Create the SMB account for ${shareUser}";
          partOf = [ "samba-smbd.service" ];
          path = [ pkgs.samba4 ];
          script = ''
            if ! pdbedit -L | grep -q '^${shareUser}:'; then
              pw=$(cat ${config.sops.secrets.samba-user-pw.path})
              printf '%s\n%s\n' "$pw" "$pw" | smbpasswd -a -s ${shareUser}
            fi
          '';
          serviceConfig.Type = "oneshot";
          wantedBy = [ "samba-smbd.service" ];
        };
      };
    };
}
