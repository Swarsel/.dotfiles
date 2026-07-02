{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.ankisync
    self.modules.nixos.invidious-companion
    self.modules.nixos.socks-proxy
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

}
