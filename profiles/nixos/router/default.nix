{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${m}/nixos/server/nftables.nix"
    "${m}/nixos/server/router.nix"
    "${m}/nixos/server/kea.nix"
  ];
}
