{ self, config, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    # common modules
    "${m}/nixos/common/settings.nix"
    "${m}/nixos/common/lanzaboote.nix"
    "${m}/nixos/common/pii.nix"
    "${m}/nixos/common/home-manager.nix"
    "${m}/nixos/common/xserver.nix"
    "${m}/nixos/common/time.nix"
    "${m}/nixos/common/users.nix"
    "${m}/nixos/common/impermanence.nix"
    "${m}/nixos/common/sops.nix"
    "${m}/nixos/common/boot.nix"
    # client modules (same as personal, minus yubikey)
    "${m}/nixos/client/appimage.nix"
    "${m}/nixos/client/autologin.nix"
    "${m}/nixos/client/blueman.nix"
    "${m}/nixos/client/distrobox.nix"
    "${m}/nixos/client/env.nix"
    "${m}/nixos/client/firezone-client.nix"
    "${m}/nixos/client/gnome-keyring.nix"
    "${m}/nixos/client/gvfs.nix"
    "${m}/nixos/client/hardware.nix"
    "${m}/nixos/client/interceptiontools.nix"
    "${m}/nixos/client/hardwarecompatibility-keyboards.nix"
    "${m}/nixos/client/hardwarecompatibility-ledger.nix"
    "${m}/nixos/client/lid.nix"
    "${m}/nixos/client/login.nix"
    "${m}/nixos/client/nautilus.nix"
    "${m}/nixos/client/network.nix"
    "${m}/nixos/client/networkdevices.nix"
    "${m}/nixos/client/nix-ld.nix"
    "${m}/nixos/client/nvd-rebuild.nix"
    "${m}/nixos/client/packages.nix"
    "${m}/nixos/client/pipewire.nix"
    "${m}/nixos/client/polkit.nix"
    "${m}/nixos/client/power-profiles-daemon.nix"
    "${m}/nixos/client/programs.nix"
    "${m}/nixos/client/pulseaudio.nix"
    "${m}/nixos/client/remotebuild.nix"
    "${m}/nixos/client/stylix.nix"
    "${m}/nixos/client/syncthing.nix"
    "${m}/nixos/client/systemd.nix"
    "${m}/nixos/client/uwsm.nix"
    "${m}/nixos/client/xdg-portal.nix"
    "${m}/nixos/client/zsh.nix"
    # NO yubikey
    # server modules
    "${m}/nixos/server/btrfs.nix"
    "${m}/nixos/server/nftables.nix"
  ];

  config.home-manager.users."${config.swarselsystems.mainUser}" = {
    imports = [
      "${m}/../profiles/home/hotel"
    ];
  };
}
