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
      nfsUser = globals.user.name;
      inherit (config.swarselsystems) sopsFile;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "nfs" ];
        sops.secrets.samba-user-pw = {
          inherit sopsFile;
          mode = "0400";
        };
        users.persistentIds = {
          avahi = confLib.mkIds 978;
        };
        services = {
          avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
            publish = {
              enable = true;
              userServices = true; # Needed to allow samba to automatically register mDNS records without the need for an `extraServiceFile`
            };
          };
          # add a user with sudo smbpasswd -a <user>
          samba = {
            enable = true;
            package = pkgs.samba4;
            openFirewall = true;
            settings.Eternor = {
              browseable = "yes";
              comment = "Eternor";
              "create mask" = "0660";
              "directory mask" = "2770";
              "guest ok" = "no";
              path = "/storage";
              "read only" = "no";
              "valid users" = nfsUser;
              writable = "true";
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
          description = "Ensure SMB password is set for ${nfsUser}";
          partOf = [ "samba-smbd.service" ];
          path = with pkgs; [
            samba4
            coreutils
            gnugrep
          ];
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
          serviceConfig.Type = "oneshot";
          wantedBy = [ "samba-smbd.service" ];
        };
      };
    }

  ;
}
