{
  flake.modules.nixos.distrobox = { pkgs, confLib, ... }: {
    config = {

      users.persistentIds.podman = confLib.mkIds 969;
      environment.systemPackages = with pkgs; [
        distrobox
        boxbuddy
      ];
      virtualisation.podman = {
        enable = true;
        package = pkgs.podman;
        dockerCompat = true;
      };
    };
  };
}
