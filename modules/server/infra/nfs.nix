{
  flake.modules.nixos.nfs =
    {
      lib,
      config,
      pkgs,
      globals,
      confLib,
      ...
    }:
    let
      nfsUser = globals.user.name;
      inherit (config.swarselsystems) sopsFile;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "nfs" ];

        users.persistentIds = {
          avahi = confLib.mkIds 978;
        };

        sops.secrets.samba-user-pw = {
          inherit sopsFile;
          mode = "0400";
        };

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            { directory = "/var/cache/samba"; }
            { directory = "/var/lib/samba"; }
          ];
        };

        systemd.services.samba-ensure-user-pw = {
          description = "Ensure SMB password is set for ${nfsUser}";
          after = [ "samba-smbd.service" ];
          wantedBy = [ "samba-smbd.service" ];
          partOf = [ "samba-smbd.service" ];
          path = with pkgs; [
            samba4
            coreutils
            gnugrep
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            if pdbedit -L 2>/dev/null | grep -q '^${nfsUser}:'; then
              echo "${nfsUser} SMB account already exists"
              exit 0
            fi
            echo "${nfsUser} SMB account missing — creating"
            PW=$(cat ${config.sops.secrets.samba-user-pw.path})
            printf '%s\n%s\n' "$PW" "$PW" | smbpasswd -a -s ${nfsUser}
            echo "Created ${nfsUser} SMB account"
          '';
        };

        services = {
          # add a user with sudo smbpasswd -a <user>
          samba = {
            package = pkgs.samba4;
            enable = true;
            openFirewall = true;
            settings.Eternor = {
              browseable = "yes";
              "read only" = "no";
              "guest ok" = "no";
              path = "/storage";
              writable = "true";
              comment = "Eternor";
              "valid users" = nfsUser;
              "create mask" = "0660";
              "directory mask" = "2770";
            };
          };

          avahi = {
            publish.enable = true;
            publish.userServices = true; # Needed to allow samba to automatically register mDNS records without the need for an `extraServiceFile`
            nssmdns4 = true;
            enable = true;
            openFirewall = true;
          };

          # This enables autodiscovery on windows since SMB1 (and thus netbios) support was discontinued
          samba-wsdd = {
            enable = true;
            openFirewall = true;
          };
        };
      };
    }

  ;
}
