{ lib, config, nixosConfig, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1;
  inherit (nixosConfig.repo.secrets.common) fullName;
in
{
  options.swarselsystems.modules.git = lib.mkEnableOption "git settings";
  config = lib.mkIf config.swarselsystems.modules.git {
    programs.git = {
      enable = true;
      aliases = {
        a = "add";
        c = "commit";
        cl = "clone";
        co = "checkout";
        b = "branch";
        i = "init";
        m = "merge";
        s = "status";
        r = "restore";
        p = "pull";
        pp = "push";
      };
      signing = {
        key = "0x76FD3810215AE097";
        signByDefault = true;
      };
      userEmail = lib.mkDefault address1;
      userName = fullName;
      difftastic.enable = true;
      lfs.enable = true;
      includes = [
        {
          contents = {
            github = {
              user = "Swarsel";
            };
            commit = {
              template = "~/.gitmessage";
            };
          };
        }
      ];
    };
  };
}
