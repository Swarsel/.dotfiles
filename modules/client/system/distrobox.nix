{
  flake.modules.nixos.distrobox = { pkgs, confLib, ... }: {
    config = {

      users.persistentIds.podman = confLib.mkIds 969;
      environment.systemPackages = [ pkgs.distrobox ];
      virtualisation.podman = {
        enable = true;
        package = pkgs.podman;
        dockerCompat = true;
      };
    };
  };
}
