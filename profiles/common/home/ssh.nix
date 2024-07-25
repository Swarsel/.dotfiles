_:
{
  programs.ssh = {
    enable = true;
    forwardAgent = true;
    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
    matchBlocks = {
      "nginx" = {
        hostname = "192.168.1.14";
        user = "root";
      };
      "jellyfin" = {
        hostname = "192.168.1.16";
        user = "root";
      };
      "pfsense" = {
        hostname = "192.168.1.1";
        user = "root";
      };
      "proxmox" = {
        hostname = "192.168.1.2";
        user = "root";
      };
      "transmission" = {
        hostname = "192.168.1.6";
        user = "root";
      };
      "fetcher" = {
        hostname = "192.168.1.7";
        user = "root";
      };
      "omv" = {
        hostname = "192.168.1.3";
        user = "root";
      };
      "webbot" = {
        hostname = "192.168.1.11";
        user = "root";
      };
      "nextcloud" = {
        hostname = "192.168.1.5";
        user = "root";
      };
      "sound" = {
        hostname = "192.168.1.13";
        user = "root";
      };
      "spotify" = {
        hostname = "192.168.1.17";
        user = "root";
      };
      "wordpress" = {
        hostname = "192.168.1.9";
        user = "root";
      };
      "turn" = {
        hostname = "192.168.1.18";
        user = "root";
      };
      "hugo" = {
        hostname = "192.168.1.19";
        user = "root";
      };
      "matrix" = {
        hostname = "192.168.1.23";
        user = "root";
      };
      "scroll" = {
        hostname = "192.168.1.22";
        user = "root";
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
        forwardAgent = true;
        user = "ep01427399";
      };
    };
  };
}
