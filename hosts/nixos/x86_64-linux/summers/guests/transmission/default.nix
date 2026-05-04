{ self, lib, minimal, ... }:
{
  imports = [

    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
  };


} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 4;
    vcpu = 2;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    transmission = true;
  };

}
