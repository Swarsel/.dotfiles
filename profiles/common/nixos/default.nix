{ ... }:
{
  imports = [
    ./xserver.nix
    ./users.nix
    ./env.nix
    ./stylix.nix
    ./polkit.nix
    ./gc.nix
    ./store.nix
    ./systemd.nix
    ./network.nix
    ./time.nix
    ./hardware.nix
    ./sops.nix
    ./packages.nix
    ./programs.nix
    ./zsh.nix
    ./syncthing.nix
    ./blueman.nix
    ./networkdevices.nix
    ./gvfs.nix
    ./interceptiontools.nix
    ./hardwarecompatibility.nix
    ./login.nix
  ];


  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
