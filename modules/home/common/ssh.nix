{ lib, config, confLib, type, ... }:
{
  options.swarselmodules.ssh = lib.mkEnableOption "ssh settings";
  config = lib.mkIf config.swarselmodules.ssh ({
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
          controlMaster = "auto";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "5m";
        };
      } // confLib.getConfig.repo.secrets.common.ssh.hosts;
    };
  } // lib.optionalAttrs (type != "nixos") {
    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic && !config.swarselsystems.isNixos) {
      builder-key = { path = "${config.home.homeDirectory}/.ssh/builder"; mode = "0600"; };
    };
  });
}
