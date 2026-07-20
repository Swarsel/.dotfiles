{
  flake-file.inputs.noctalia-greeter = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:noctalia-dev/noctalia-greeter";
  };

  flake.modules.nixos.login =
    {
      inputs,
      config,
      confLib,
      ...
    }:
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];
      config = {

        users.persistentIds.greeter = confLib.mkIds 958;
        services.greetd = {
          enable = true;
          settings.initial_session.command = "uwsm start -- niri-uwsm.desktop";
        };
        programs.noctalia-greeter.enable = true;
        environment = {
          pathsToLink = [ "/share/wayland-sessions" ];
          systemPackages = config.services.displayManager.sessionPackages;
        };

      };
    };
}
