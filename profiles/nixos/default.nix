{ lib, ... }:
let
  profileNames = lib.swarselsystems.readNix "profiles/nixos";
in
{
  imports = lib.swarselsystems.mkImports profileNames "profiles/nixos";
}
