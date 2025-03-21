{ lib, ... }:
{
  options.swarselsystems = {
    isDarwin = lib.mkEnableOption "darwin host";
    isLinux = lib.mkEnableOption "whether this is a linux machine";
  };
}
