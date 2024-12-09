_:
{
  imports = [
    ./settings.nix
    ./home-manager.nix
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
    # ./yubikey-touch-detector.nix
    # ./safeeyes.nix
    ./distrobox.nix
    ./lid.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "jitsi-meet-1.0.8043"
    "electron-29.4.6"
  ];

}
