{ lib, inputs, ... }:
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
    ./pipewire.nix
    ./sops.nix
    ./packages.nix
    ./programs.nix
    ./zsh.nix
    ./syncthing.nix
    ./blueman.nix
    ./safeeyes.nix
    ./networkdevices.nix
    ./gvfs.nix
    ./interceptiontools.nix
    ./hardwarecompatibility.nix
    ./login.nix
    ./stylix.nix
    ./power-profiles-daemon.nix
    # ./impermanence.nix
    ./nvd-rebuild.nix
    ./nix-ld.nix
    ./gnome-keyring.nix
    ./sway.nix
    ./xdg-portal.nix
  ];

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
        ];
        trusted-users = [ "swarsel" ];
        flake-registry = "";
        warn-dirty = false;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.stateVersion = lib.mkDefault "23.05";
}
