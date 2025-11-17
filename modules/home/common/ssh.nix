{ lib, config, nixosConfig ? config, ... }:
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
      } // nixosConfig.repo.secrets.common.ssh.hosts;
    };
  };
}
