{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      initial_session.command = "sway";
      # initial_session.user ="swarsel";
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time \
          --asterisks \
          --user-menu \
          --cmd sway
      '';
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
  '';
}
