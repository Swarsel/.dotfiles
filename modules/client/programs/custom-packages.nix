{
  flake.modules.homeManager.custom-packages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "ownpackages" ];
        home.packages =
          with pkgs;
          lib.mkIf (!config.swarselsystems.isPublic) [
            pass-fuzzel
            swarsel-bootstrap
            swarsel-deploy
            swarsel-instantiate
            swarsel-git-remotes
            hunkle
            swarsel-gens
            swarsel-project
            swarsel-switch
            swarsel-sync-org
            follow-nix
          ];
      };
    };
}
