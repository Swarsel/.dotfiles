{ self, config, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos"
    "${self}/modules/nixos/optional/microvm-guest-shares.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

  globals.general.homeDnsServer = config.node.name;

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    adguardhome = true;
  };

}
