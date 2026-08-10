{
  self,
  lib,
  pkgs,
  system,
  ...
}:
let
  packagePlatforms = {
    build-topology-images = lib.platforms.linux;
    cura5 = lib.platforms.linux;
    e = lib.platforms.linux;
    e-niri = lib.platforms.linux;
    fs-diff = lib.platforms.linux;
    kanshare = lib.platforms.linux;
    nirishare = lib.platforms.linux;
    opacitytoggle = lib.platforms.linux;
    pass-fuzzel = lib.platforms.linux;
    swarsel-displaypower = lib.platforms.linux;
    swarsel-install = lib.platforms.linux;
    swarsel-mgba = lib.platforms.linux;
    swarsel-postinstall = lib.platforms.linux;
    swarsel-rebuild = lib.platforms.linux;
    swarselcheck = lib.platforms.linux;
    swarselcheck-niri = lib.platforms.linux;
    t2ts = lib.platforms.linux;
    waybarupdate = lib.platforms.linux;
  };

  supportedOn =
    name: !(packagePlatforms ? ${name}) || builtins.elem system packagePlatforms.${name};

  mkPackages =
    names: pkgs:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = pkgs.callPackage "${self}/pkgs/flake/${name}" { inherit self name; };
      }) (builtins.filter supportedOn names)
    );
  packageNames = lib.swarselsystems.readNix "pkgs/flake";
in
mkPackages packageNames pkgs
