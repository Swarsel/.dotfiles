{
  flake.modules.nixos.network-scanner =
    { pkgs, globals, ... }:
    {
      environment.etc."sane.d/airscan.conf".text = ''
        [devices]
        "Dell C2665dnf" = http://${globals.networks.home-lan.vlans.devices.hosts.dell-C2665dnf-F49D60.ipv4}/ws, wsd
      '';
      hardware.sane = {
        enable = true;
        extraBackends = [ pkgs.sane-airscan ];
      };
    };
}
