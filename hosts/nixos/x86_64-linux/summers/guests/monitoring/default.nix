{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/server/grafana.nix"
    "${self}/modules/nixos/server/mimir.nix"
    "${self}/modules/nixos/server/loki.nix"
    "${self}/modules/nixos/server/tempo.nix"
    "${self}/modules/nixos/server/pyroscope.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
    nodeRoles = [ "monitoringServer" ];
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 24;
    vcpu = 8;
  };

}
