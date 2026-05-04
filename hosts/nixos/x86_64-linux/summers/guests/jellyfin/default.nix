{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };


} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 3;
    vcpu = 4;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    jellyfin = true;
  };

}
