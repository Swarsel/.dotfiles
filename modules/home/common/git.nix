{ lib, config, globals, minimal, nixosConfig ? config, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1;
  inherit (nixosConfig.repo.secrets.common) fullName;

  gitUser = globals.user.name;
in
{
  options.swarselmodules.git = lib.mkEnableOption "git settings";
  config = lib.mkIf config.swarselmodules.git {
    programs.git = {
      enable = true;
    } // lib.optionalAttrs (!minimal) {
      settings = {
        alias = {
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
        user = {
          email = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) (lib.mkDefault address1);
          name = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) fullName;
        };
      };
      signing = {
        key = "0x76FD3810215AE097";
        signByDefault = true;
      };
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
    programs.difftastic.enable = lib.mkIf (!minimal) true;
  };
}
