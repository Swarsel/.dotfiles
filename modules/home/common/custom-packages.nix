{ lib, config, pkgs, ... }:

{
  config = {
    swarselsystems.enabledHomeModules = [ "ownpackages" ];
    home.packages = with pkgs; lib.mkIf (!config.swarselsystems.isPublic) ([
      pass-fuzzel
      cdw
      cdb
      cdr
      bak
      timer
      waybarupdate
      opacitytoggle
      fs-diff
      github-notifications
      hm-specialisation
      t2ts
      ts2t
      vershell
      eontimer
      project
      fhs
      swarsel-bootstrap
      swarsel-build
      swarsel-deploy
      swarsel-instantiate
      swarselzellij
      sshrm
      endme
      git-replace
      prstatus
      swarsel-gens
      swarsel-switch
      swarsel-sops
      sync-org-from-files
    ] ++ lib.optionals (builtins.elem "sway" config.swarselsystems.enabledHomeModules) [
      e
      swarselcheck
      swarsel-displaypower
    ] ++ lib.optionals (builtins.elem "optional-niri" config.swarselsystems.enabledHomeModules) [
      e-niri
      swarselcheck-niri
    ]);
  };
}
