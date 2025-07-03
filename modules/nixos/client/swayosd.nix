{ lib, pkgs, config, ... }:
{
  options.swarselsystems.modules.swayosd = lib.mkEnableOption "swayosd settings";
  config = lib.mkIf config.swarselsystems.modules.swayosd {
    environment.systemPackages = [ pkgs.swayosd ];
    services.udev.packages = [ pkgs.swayosd ];
    systemd.services.swayosd-libinput-backend = {
      description = "SwayOSD LibInput backend for listening to certain keys like CapsLock, ScrollLock, VolumeUp, etc.";
      documentation = [ "https://github.com/ErikReider/SwayOSD" ];
      wantedBy = [ "graphical.target" ];
      partOf = [ "graphical.target" ];
      after = [ "graphical.target" ];

      serviceConfig = {
        Type = "dbus";
        BusName = "org.erikreider.swayosd";
        ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
        Restart = "on-failure";
      };
    };
  };
}
