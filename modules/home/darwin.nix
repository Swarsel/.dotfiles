{ lib, config, ... }:
{
  options.swarselsystems.isDarwin = lib.mkEnableOption "darwin host";
}
