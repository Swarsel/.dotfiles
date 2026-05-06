{ config, lib, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "bash" ];

    programs.bash = {
      enable = true;
      # needed for remote builders
      bashrcExtra = lib.mkIf (!config.swarselsystems.isNixos) ''
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"
      '';
      historyFile = "${config.home.homeDirectory}/.histfile";
      historySize = 100000;
      historyFileSize = 100000;
      historyControl = [
        "ignoreboth"
      ];
    };
  };
}
