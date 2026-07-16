{
  flake.modules = {
    homeManager.swayosd = { pkgs, confLib, ... }: {
      config = {
        swarselsystems.enabledHomeModules = [ "swayosd" ];
        services.swayosd = {
          enable = true;
          package = pkgs.swayosd;
          topMargin = 0.5;
        };
        systemd.user.services.swayosd = confLib.overrideTarget "sway-session.target";
      };
    };
    nixos.swayosd = { pkgs, ... }: {
      config = {
        services.udev.packages = [ pkgs.swayosd ];
        environment.systemPackages = [ pkgs.swayosd ];
        systemd.services.swayosd-libinput-backend = {
          after = [ "graphical.target" ];
          description = "SwayOSD LibInput backend for listening to certain keys like CapsLock, ScrollLock, VolumeUp, etc.";
          documentation = [ "https://github.com/ErikReider/SwayOSD" ];
          partOf = [ "graphical.target" ];
          serviceConfig = {
            BusName = "org.erikreider.swayosd";
            ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
            Restart = "on-failure";
            Type = "dbus";
          };
          wantedBy = [ "graphical.target" ];
        };
      };
    };
  };
}
