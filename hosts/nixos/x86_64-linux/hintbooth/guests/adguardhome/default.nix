{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.microvm-guest-shares
    self.modules.nixos.adguardhome
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
    nodeRoles = [ "homeDnsServer" ];
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

}
