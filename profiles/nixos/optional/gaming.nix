{ pkgs, ... }:
{
  specialisation = {
    gaming.configuration = {
      networking = {
        firewall = {
          allowedUDPPorts = [ 4380 27036 14242 34197 ]; # 34197: factorio; 4380 27036 14242: barotrauma;
          allowedTCPPorts = [ ]; # 34197: factorio; 4380 27036 14242: barotrauma; 51820: wireguard
          allowedTCPPortRanges = [
            { from = 27015; to = 27030; } # barotrauma
            { from = 27036; to = 27037; } # barotrauma
          ];
          allowedUDPPortRanges = [
            { from = 27000; to = 27031; } # barotrauma
            { from = 58962; to = 58964; } # barotrauma
          ];
        };
      };

      programs.steam = {
        enable = true;
        package = pkgs.steam;
        extraCompatPackages = [
          pkgs.proton-ge-bin
        ];
      };

      hardware.xone.enable = true;

      environment.systemPackages = [
        pkgs.linuxKernel.packages.linux_6_12.xone
      ];
    };
  };

}
