{
  flake.modules = {
    nixos.swayosd = { pkgs, ... }: {
      config = {
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
    };

    homeManager.swayosd = { pkgs, confLib, ... }: {
      config = {
        swarselsystems.enabledHomeModules = [ "swayosd" ];
        systemd.user.services.swayosd = confLib.overrideTarget "sway-session.target";
        services.swayosd = {
          enable = true;
          package = pkgs.swayosd;
          topMargin = 0.5;
        };
      };
    };
  };
}
