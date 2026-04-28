{ lib, config, pkgs, ... }:

{
  options.swarselmodules.ownpackages = lib.mkEnableOption "own packages settings";
  config = lib.mkIf config.swarselmodules.ownpackages {
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
      swarsel-displaypower
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
    ] ++ lib.optionals config.swarselmodules.sway [
      e
      swarselcheck
    ] ++ lib.optionals (config.swarselmodules ? optional-niri) [
      e-niri
      swarselcheck-niri
    ]);
  };
}
