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
    mem = 1024 * 8;
    vcpu = 4;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    paperless = true;
  };

}
