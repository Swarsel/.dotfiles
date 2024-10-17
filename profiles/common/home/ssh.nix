_:
{
  programs.ssh = {
    enable = true;
    forwardAgent = true;
    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
    matchBlocks = {
      # Local machines
      "pfsense" = {
        hostname = "192.168.1.1";
        user = "root";
      };
      "winters" = {
        hostname = "192.168.1.2";
        user = "swarsel";
      };
      "minecraft" = {
        hostname = "130.61.119.129";
        user = "opc";
      };
      "sync" = {
        hostname = "193.122.53.173";
        user = "root"; #this is a oracle vm server but needs root due to nixos-infect
      };
      "songdiver" = {
        hostname = "89.168.100.65";
        user = "ubuntu";
      };
      "pkv" = {
        hostname = "46.232.248.161";
        user = "root";
      };
      "efficient" = {
        hostname = "g0.complang.tuwien.ac.at";
        user = "ep01427399";
      };
    };
  };
}
