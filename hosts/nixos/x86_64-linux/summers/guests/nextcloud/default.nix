{ self, lib, minimal, ... }:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.nextcloud
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 3;
    vcpu = 2;
  };

}
