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
    mem = 1024 * 1;
    vcpu = 2;

  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    kavita = true;
  };

}
