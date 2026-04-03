{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/modules/nixos/optional/microvm-guest.nix"
  ];

  swarselsystems = {
    info = "ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM";
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = false;
  };

  microvm = {
    mem = 1024 * 4;
    vcpu = 2;
  };

}
