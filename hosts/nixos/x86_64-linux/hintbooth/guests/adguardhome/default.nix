{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/optional/microvm-guest-shares.nix"
    "${self}/modules/nixos/server/adguardhome.nix"
  ];

  swarselsystems = {
    nodeRoles = [ "homeDnsServer" ];
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

}
