{ pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  pass-fuzzel = callPackage ./pass-fuzzel { };
  pass-fuzzel-otp = callPackage ./pass-fuzzel-otp { };
}
