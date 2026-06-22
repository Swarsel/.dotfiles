{
  flake.modules = {
    nixos.gnome-keyring = {
      config = {
        services.gnome.gnome-keyring = {
          enable = true;
        };

        programs.seahorse.enable = true;
      };
    };

    homeManager.gnome-keyring =
      {
        lib,
        nixosConfig ? null,
        ...
      }:
      {
        config = {
          swarselsystems.enabledHomeModules = [ "gnome-keyring" ];
          services.gnome-keyring = lib.mkIf (nixosConfig == null) {
            enable = true;
          };
        };
      };
  };
}
