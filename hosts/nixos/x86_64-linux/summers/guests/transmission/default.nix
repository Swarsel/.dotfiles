{ self, lib, minimal, ... }:
{
  imports = [

    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/server/transmission.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 6;
    vcpu = 6;
  };

}
