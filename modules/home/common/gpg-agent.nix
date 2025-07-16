{ self, lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
in
{
  options.swarselmodules.gpgagent = lib.mkEnableOption "gpg agent settings";
  config = lib.mkIf config.swarselmodules.gpgagent {
    services.gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      enableScDaemon = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      pinentry.package = pkgs.pinentry.gtk2;
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
      "d ${homeDir}/.gnupg 700 ${mainUser} users"
    ];
  };

}
