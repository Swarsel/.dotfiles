{
  flake.modules.nixos.hardwarecompatibility-keyboards =
    {
      lib,
      pkgs,
      confLib,
      ...
    }:
    {
      config = {
        users.persistentIds.plugdev = confLib.mkIds 953;
        services.udev.packages =
          with pkgs;
          [
            qmk-udev-rules
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
            vial
            via
          ];
      };
    };
}
