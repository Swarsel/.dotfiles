{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };


} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 16;
    vcpu = 14;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    immich = true;
  };

}
