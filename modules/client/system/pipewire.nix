{
  flake.modules.nixos.pipewire = { pkgs, confLib, ... }: {
    config = {
      users.persistentIds.rtkit = confLib.mkIds 996;
      services.pipewire = {
        enable = true;
        package = pkgs.pipewire;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        audio.enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
      security.rtkit.enable = true; # this is required for pipewire real-time access
    };
  };
}
