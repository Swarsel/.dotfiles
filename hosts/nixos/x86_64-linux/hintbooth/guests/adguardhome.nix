{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos"
  ];

  swarselsystems = {
    isMicroVM = true;
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

  swarselprofiles = {
    microvm = true;
  };

}
