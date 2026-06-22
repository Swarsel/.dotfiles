{
  flake.modules.homeManager.custom-packages =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "ownpackages" ];
        home.packages =
          with pkgs;
          lib.mkIf (!config.swarselsystems.isPublic) (
            [
              pass-fuzzel
              cdw
              cdb
              cdr
              bak
              waybarupdate
              opacitytoggle
              fs-diff
              github-notifications
              t2ts
              ts2t
              vershell
              project
              swarsel-bootstrap
              swarsel-build
              swarsel-deploy
              swarsel-instantiate
              swarselzellij
              sshrm
              git-replace
              hunkle
              swarsel-gens
              swarsel-switch
              swarsel-sops
              sync-org-from-files
            ]
            ++ lib.optionals (builtins.elem "sway" config.swarselsystems.enabledHomeModules) [
              e
              swarselcheck
              swarsel-displaypower
            ]
            ++ lib.optionals (builtins.elem "optional-niri" config.swarselsystems.enabledHomeModules) [
              e-niri
              swarselcheck-niri
            ]
          );
      };
    };
}
