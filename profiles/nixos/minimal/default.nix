{ lib, config, ... }:
{
  options.swarselprofiles.minimal = lib.mkEnableOption "declare this a minimal host";
  config = lib.mkIf config.swarselprofiles.minimal {
    swarselmodules = {
      general = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      lanzaboote = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      security = lib.mkDefault true;
      sops = lib.mkDefault true;
      pii = lib.mkDefault true;
      zsh = lib.mkDefault true;
      yubikey = lib.mkDefault true;
      autologin = lib.mkDefault true;
      boot = lib.mkDefault true;
      btrfs = lib.mkDefault true;

      server = {
        ssh = lib.mkDefault true;
      };
    };

  };

}
