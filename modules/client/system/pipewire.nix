{
  flake.modules.nixos.pipewire = { pkgs, confLib, ... }: {
    config = {
      security.rtkit.enable = true; # this is required for pipewire real-time access

      users.persistentIds.rtkit = confLib.mkIds 996;

      services.pipewire = {
        enable = true;
        package = pkgs.pipewire;
        pulse.enable = true;
        jack.enable = true;
        audio.enable = true;
        wireplumber.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
  };
}
