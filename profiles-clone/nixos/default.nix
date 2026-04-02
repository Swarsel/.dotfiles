{ lib, ... }:
let
  profileNames = lib.swarselsystems.readNix "profiles-clone/nixos";
in
{
  imports = lib.swarselsystems.mkImports profileNames "profiles-clone/nixos";
}
