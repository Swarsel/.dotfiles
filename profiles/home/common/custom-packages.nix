{ config, pkgs, ... }:

{
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
    update-checker
    github-notifications
    screenshare
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

    rustdesk-vbc
  ];
}
