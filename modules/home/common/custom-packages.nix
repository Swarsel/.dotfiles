{ lib, config, pkgs, ... }:

{
  options.swarselsystems.modules.ownpackages = lib.mkEnableOption "own packages settings";
  config = lib.mkIf config.swarselsystems.modules.ownpackages {
    home.packages = with pkgs; lib.mkIf (!config.swarselsystems.isPublic) [
      pass-fuzzel
      cura5
      cdw
      cdb
      bak
      timer
      e
      swarselcheck
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
      swarselzellij
      sshrm

      rustdesk-vbc
    ];
  };
}
