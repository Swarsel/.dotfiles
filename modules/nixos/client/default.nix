{ lib, inputs, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/client";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/client" ++ [
    inputs.stylix.nixosModules.stylix
    inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
  ];
}
