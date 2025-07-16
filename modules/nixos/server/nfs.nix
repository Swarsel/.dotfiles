{ lib, config, pkgs, globals, ... }:
let
  nfsUser = globals.user.name;
in
{
  options.swarselmodules.server.nfs = lib.mkEnableOption "enable nfs on server";
  config = lib.mkIf config.swarselmodules.server.nfs {
    services = {
      # add a user with sudo smbpasswd -a <user>
      samba = {
        package = pkgs.samba4Full;
        # extraConfig = ''
        #   workgroup = WORKGROUP
        #   server role = standalone server
        #   dns proxy = no

        #   pam password change = yes
        #   map to guest = bad user
        #   create mask = 0664
        #   force create mode = 0664
        #   directory mask = 0775
        #   force directory mode = 0775
        #   follow symlinks = yes
        # '';

        enable = true;
        openFirewall = true;
        settings.Eternor = {
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          path = "/Vault/Eternor";
          writable = "true";
          comment = "Eternor";
          "valid users" = nfsUser;
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
