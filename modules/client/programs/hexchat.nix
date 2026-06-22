{
  flake.modules.homeManager.hexchat =
    { confLib, ... }:
    let
      moduleName = "hexchat";
      inherit (confLib.getConfig.repo.secrets.common.irc) irc_nick1;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "hexchat" ];
        programs.${moduleName} = {
          enable = true;
          settings = {
            inherit irc_nick1;
          };
        };
      };
    };
}
