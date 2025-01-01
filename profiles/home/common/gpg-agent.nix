{ self, pkgs, ... }:
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry.gtk2;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    extraConfig = ''
      allow-loopback-pinentry
      allow-emacs-pinentry
    '';
    sshKeys = [
      "4BE7925262289B476DBBC17B76FD3810215AE097"
    ];
  };

  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = "${self}/secrets/keys/gpg/gpg-public-key-0x76FD3810215AE097.asc";
        trust = 5;
      }
    ];
  };

  # assure correct permissions
  systemd.user.tmpfiles.rules = [
    "d /home/swarsel/.gnupg 700 swarsel users"
  ];

}
