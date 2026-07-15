{
  flake.modules.homeManager.git =
    {
      lib,
      config,
      globals,
      minimal,
      confLib,
      nixosConfig ? null,
      ...
    }:
    let
      inherit (confLib.getConfig.repo.secrets.common.mail) address1;
      inherit (confLib.getConfig.repo.secrets.common) fullName;
      inherit (config.swarselsystems) mainUser homeDir;

      gitUser = globals.user.name;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "git" ];

        systemd.user.tmpfiles.rules = [
          "f ${homeDir}/.gitconfig 0644 ${mainUser} users - -"
        ];

        programs.git = {
          enable = true;
        }
        // lib.optionalAttrs (!minimal) {
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
              email = lib.mkIf ((nixosConfig != null) && !config.swarselsystems.isPublic) (
                lib.mkDefault address1
              );
              name = lib.mkIf ((nixosConfig != null) && !config.swarselsystems.isPublic) fullName;
            };
          };
          signing = {
            key = "0x76FD3810215AE097";
            signByDefault = true;
            format = "openpgp";
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
    };
}
