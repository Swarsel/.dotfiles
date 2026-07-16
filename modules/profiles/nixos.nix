{ config, lib, ... }:
let
  fmods = config.flake.modules;
  pickN = names: builtins.attrValues (lib.getAttrs names fmods.nixos);
in
{
  flake.modules.nixos = {
    profile-minimal = {
      imports =
        pickN [
          "settings"
          "home-manager"
          "xserver"
          "lanzaboote"
          "time"
          "users"
          "impermanence"
          "sops"
          "boot"
          "autologin"
          "btrfs"
          "ssh"
          "disk-encrypt"
        ]
        ++ [
          fmods.generic.pii
        ];
    };
    profile-personal = { config, ... }: {
      imports = [
        fmods.nixos.profile-public
      ]
      ++ pickN [
        "hardwarecompatibility-yubikey"
        "sandbox-access"
        "ssh"
      ];
      home-manager.users."${config.swarselsystems.mainUser}".imports = [
        fmods.homeManager.profile-personal
      ];
    };
    profile-public = { config, ... }: {
      imports = [
        fmods.nixos.profile-public-small
      ]
      ++ pickN [
        "appimage"
        "distrobox"
        "hardwarecompatibility-keyboards"
        "hardwarecompatibility-ledger"
        "lid"
        "networkdevices"
        "nix-ld"
      ];
      home-manager.users."${config.swarselsystems.mainUser}".imports = [
        fmods.homeManager.profile-public
      ];
    };
    profile-public-small = { config, ... }: {
      imports =
        pickN [
          "settings"
          "lanzaboote"
          "home-manager"
          "xserver"
          "time"
          "users"
          "impermanence"
          "sops"
          "boot"
          "autologin"
          "blueman"
          "env"
          "firezone-client"
          "gnome-keyring"
          "gvfs"
          "hardware"
          "interceptiontools"
          "login"
          "nautilus"
          "network"
          "nvd-rebuild"
          "packages"
          "pipewire"
          "polkit"
          "power-profiles-daemon"
          "programs"
          "pulseaudio"
          "remotebuild"
          "stylix"
          "syncthing"
          "systemd"
          "uwsm"
          "xdg-portal"
          "zsh"
          "btrfs"
          "nftables-rules"
        ]
        ++ [
          fmods.generic.pii
        ];
      home-manager.users."${config.swarselsystems.mainUser}".imports = [
        fmods.homeManager.profile-public-small
      ];
    };
  };
}
