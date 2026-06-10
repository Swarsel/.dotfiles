{
  flake.modules.nixos.login = { pkgs, confLib, ... }: {
    config = {

      users.persistentIds = {
        greeter = confLib.mkIds 958;
      };

      services.greetd = {
        enable = true;
        settings = {
          initial_session.command = "uwsm start -- niri-uwsm.desktop";
          default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --user-menu --cmd 'uwsm start -- niri-uwsm.desktop'";
        };
      };

    };
  };
}
