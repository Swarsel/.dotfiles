{ pkgs, lib, config, ... }:
{

  # Network shares
  # add a user with sudo smbpasswd -a <user>
  samba = {
    package = pkgs.samba4Full;
    extraConfig = ''
      workgroup = WORKGROUP
      server role = standalone server
      dns proxy = no

      pam password change = yes
      map to guest = bad user
      create mask = 0664
      force create mode = 0664
      directory mask = 0775
      force directory mode = 0775
      follow symlinks = yes
    '';

    # ^^ `samba4Full` is compiled with avahi, ldap, AD etc support compared to the default package, `samba`
    # Required for samba to register mDNS records for auto discovery
    # See https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/pkgs/top-level/all-packages.nix#L27268
    enable = true;
    # openFirewall = true;
    shares.Eternor = {
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      path = "/Vault/Eternor";
      writable = "true";
      comment = "Eternor";
      "valid users" = "@Swarsel";
    };
  };


  avahi = {
    publish.enable = true;
    publish.userServices = true;
    # ^^ Needed to allow samba to automatically register mDNS records without the need for an `extraServiceFile`
    nssmdns4 = true;
    # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
    enable = true;
  };

  samba-wsdd = {
    # This enables autodiscovery on windows since SMB1 (and thus netbios) support was discontinued
    enable = true;
  };
};
}
