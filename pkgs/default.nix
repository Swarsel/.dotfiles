{ pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  pass-fuzzel = callPackage ./pass-fuzzel { };
  pass-fuzzel-otp = callPackage ./pass-fuzzel-otp { };
  cura5 = callPackage ./cura5 { };
  cdw = callPackage ./cdw { };
  cdb = callPackage ./cdb { };
  bak = callPackage ./bak { };
  timer = callPackage ./timer { };
}
