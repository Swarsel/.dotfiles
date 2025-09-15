{ lib, config, ... }:
{
  options.swarselmodules.ssh = lib.mkEnableOption "ssh settings";
  config = lib.mkIf config.swarselmodules.ssh {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraConfig = ''
        SetEnv TERM=xterm-256color
        ServerAliveInterval 20
      '';
      matchBlocks = {
        "*" = {
          forwardAgent = true;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
        "pfsense" = {
          hostname = "192.168.1.1";
          user = "root";
        };
        "bakery" = {
          hostname = "192.168.1.136";
          user = "root";
        };
        "winters" = {
          hostname = "192.168.178.24";
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
