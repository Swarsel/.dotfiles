{ lib, config, ... }:
{
  options.swarselsystems.modules.gc = lib.mkEnableOption "garbage collection config";
  config = lib.mkIf config.swarselsystems.modules.gc {
    nix.gc = {
      automatic = true;
      randomizedDelaySec = "14m";
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };
}
