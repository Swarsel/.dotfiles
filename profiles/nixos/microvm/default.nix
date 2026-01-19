{ lib, config, ... }:
{
  options.swarselprofiles.microvm = lib.mkEnableOption "is this a server";
  config = lib.mkIf config.swarselprofiles.microvm {
    swarselsystems = {
      isLinux = true;
      isNixos = true;
    };
    swarselmodules = {
      general = lib.mkDefault true;
      pii = lib.mkDefault true;
      xserver = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      btrfs = lib.mkDefault true;
      sops = lib.mkDefault true;
      nftables = lib.mkDefault true;
      server = {
        general = lib.mkDefault true;
        ids = lib.mkDefault true;
        packages = lib.mkDefault true;
        ssh = lib.mkDefault true;
        wireguard = lib.mkDefault true;
        dns-home = lib.mkDefault true;
        opkssh = true;
      };
    };
  };

}
