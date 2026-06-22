{
  flake-file.inputs.noctalia-greeter = {
    url = "github:noctalia-dev/noctalia-greeter";
    inputs.nixpkgs.follows = "nixpkgs";
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

        users.persistentIds = {
          greeter = confLib.mkIds 958;
        };

        environment = {
          systemPackages = config.services.displayManager.sessionPackages;
          pathsToLink = [ "/share/wayland-sessions" ];
        };

        programs.noctalia-greeter.enable = true;

        services.greetd = {
          enable = true;
          settings.initial_session.command = "uwsm start -- niri-uwsm.desktop";
        };

      };
    };
}
