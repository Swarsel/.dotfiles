{ lib, config, ... }:
{
  options.swarselprofiles.hotel = lib.mkEnableOption "is this a hotel host";
  config = lib.mkIf config.swarselprofiles.hotel {
    swarselprofiles.personal = true;
    swarselmodules = {
      yubikey = lib.mkForce false;
      ssh = lib.mkForce false;
      env = lib.mkForce false;
      git = lib.mkForce false;
      mail = lib.mkForce false;
      emacs = lib.mkForce false;
      obsidian = lib.mkForce false;
      gammastep = lib.mkForce false;
    };
  };

}
