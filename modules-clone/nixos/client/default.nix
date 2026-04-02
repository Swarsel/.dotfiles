{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/nixos/client";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/nixos/client";
}
