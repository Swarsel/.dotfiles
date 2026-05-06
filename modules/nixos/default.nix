{ self, lib, ... }:
let
  m = "${self}/modules";
  sharedNames = lib.swarselsystems.readNix "modules/shared";
in
{
  imports = lib.swarselsystems.mkImports sharedNames "modules/shared" ++ [
    "${m}/nixos/common/globals.nix"
    "${m}/nixos/common/nodes.nix"
    "${m}/nixos/common/topology.nix"
    "${m}/nixos/server/id.nix"
  ];
}
