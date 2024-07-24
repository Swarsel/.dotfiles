{ lib, config, ... }:
{
  options.swarselsystems.isNixos = lib.mkEnableOption "nixos host";
}
