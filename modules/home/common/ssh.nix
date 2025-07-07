{ lib, config, ... }:
{
  options.swarselsystems.modules.ssh = lib.mkEnableOption "ssh settings";
  config = lib.mkIf config.swarselsystems.modules.ssh {
    programs.ssh = {
      enable = true;
      forwardAgent = true;
      extraConfig = ''
        SetEnv TERM=xterm-256color
        ServerAliveInterval 20
      '';
      matchBlocks = {
        "pfsense" = {
          hostname = "192.168.1.1";
          user = "root";
        };
        "winters" = {
          hostname = "192.168.1.2";
          user = "root";
        };
        "minecraft" = {
          hostname = "130.61.119.129";
          user = "opc";
        };
        "milkywell" = {
          hostname = "193.122.53.173";
          user = "root";
        };
        "moonside" = {
          hostname = "130.61.238.239";
          user = "root";
        };
        "songdiver" = {
          hostname = "89.168.100.65";
          user = "ubuntu";
        };
        "pkv" = {
          hostname = "46.232.248.161";
          user = "root";
        };
      };
    };
  };
}
