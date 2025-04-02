{ lib, ... }:
let
  profileNames = lib.swarselsystems.readNix "profiles/home";
in
{
  imports = lib.swarselsystems.mkImports profileNames "profiles/home";
}
