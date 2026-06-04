{ self, lib, ... }:
let
  m = "${self}/modules";
  sharedNames = lib.swarselsystems.readNix "modules/shared";
in
{
  imports = lib.swarselsystems.mkImports sharedNames "modules/shared" ++ [
    "${self}/nix/flake-file-options.nix"
    "${m}/nixos/common/dns.nix"
    "${m}/nixos/common/globals.nix"
    "${m}/nixos/common/nftables.nix"
    "${m}/nixos/common/nodes.nix"
    "${m}/nixos/common/topology.nix"
    "${m}/nixos/server/id.nix"
  ];
}
