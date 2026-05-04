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
    vcpu = 1;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    freshrss = true;
    nginx = true;
    acme = false;
  };

}
