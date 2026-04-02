{ lib, ... }:
let
  profileNames = lib.swarselsystems.readNix "profiles-clone/home";
in
{
  imports = lib.swarselsystems.mkImports profileNames "profiles-clone/home";
}
