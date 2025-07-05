{ lib, config, globals, minimal, ... }:
let
  inherit (config.repo.secrets.common.mail) address1;
  inherit (config.repo.secrets.common) fullName;

  gitUser = globals.user.name;
in
{
  options.swarselsystems.modules.git = lib.mkEnableOption "git settings";
  config = lib.mkIf config.swarselsystems.modules.git {
    programs.git = {
      enable = true;
    } // lib.optionalAttrs (!minimal) {
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
      userEmail = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) (lib.mkDefault address1);
      userName = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) fullName;
      difftastic.enable = true;
      lfs.enable = true;
      includes = [
        {
          contents = {
            github = {
              user = gitUser;
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
