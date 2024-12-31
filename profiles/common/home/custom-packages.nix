{ pkgs, ... }:

{
  home.packages = with pkgs; [
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

    swarsel-bootstrap
  ];
}
