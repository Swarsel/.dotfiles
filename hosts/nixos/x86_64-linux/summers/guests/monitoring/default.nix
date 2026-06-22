{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.grafana
    self.modules.nixos.mimir
    self.modules.nixos.loki
    self.modules.nixos.tempo
    self.modules.nixos.pyroscope
    self.modules.nixos.gotify
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
    nodeRoles = [ "monitoringServer" ];
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 24;
    vcpu = 8;
  };

}
