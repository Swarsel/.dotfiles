{ pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  pass-fuzzel = callPackage ./pass-fuzzel { };
  cura5 = callPackage ./cura5 { };
  hm-specialisation = callPackage ./hm-specialisation { };
  cdw = callPackage ./cdw { };
  cdb = callPackage ./cdb { };
  bak = callPackage ./bak { };
  timer = callPackage ./timer { };
  e = callPackage ./e { };
  swarselcheck = callPackage ./swarselcheck { };
  waybarupdate = callPackage ./waybarupdate { };
  opacitytoggle = callPackage ./opacitytoggle { };
  fs-diff = callPackage ./fs-diff { };
  update-checker = callPackage ./update-checker { };
  github-notifications = callPackage ./github-notifications { };
  screenshare = callPackage ./screenshare { };
}
