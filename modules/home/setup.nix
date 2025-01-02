{ lib, ... }:
{
  options.swarselsystems.isDarwin = lib.mkEnableOption "darwin host";
  options.swarselsystems.isLinux = lib.mkEnableOption "whether this is a linux machine";
}
