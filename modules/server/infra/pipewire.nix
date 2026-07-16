{
  flake.modules.nixos.server-pipewire =
    {
      config,
      lib,
      confLib,
      ...
    }:
    {
      config = {

        swarselsystems.enabledServerModules = [ "pipewire" ];
        users.persistentIds.rtkit = confLib.mkIds 996;
        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          audio.enable = true;
          jack.enable = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/pipewire";
              group = "pipewire";
              user = "pipewire";
            }
          ];
        };
        security.rtkit.enable = true; # this is required for pipewire real-time access
      };
      key = "swarsel/server/server-pipewire";

    }

  ;
}
