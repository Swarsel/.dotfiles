{ inputs, lib, ... }:
{
  flake-file.inputs.nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";

  imports = lib.optionals (inputs ? nixos-nftables-firewall) [
    inputs.nixos-nftables-firewall.nixosModules.default
  ];
}
