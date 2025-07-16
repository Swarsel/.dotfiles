{ lib, config, pkgs, minimal, ... }:
{
  options.swarselmodules.packages = lib.mkEnableOption "install packages";
  config = lib.mkIf config.swarselmodules.packages {

    environment.systemPackages = with pkgs; lib.optionals (!minimal) [
      # yubikey packages
      gnupg
      yubikey-personalization
      yubico-pam
      yubioath-flutter
      yubikey-manager
      yubikey-touch-detector
      yubico-piv-tool
      cfssl
      pcsctools
      pcscliteWithPolkit.out

      # ledger packages
      ledger-live-desktop

      # pinentry
      dbus
      swaylock-effects
      syncthingtray-minimal
      wl-mirror
      swayosd

      # secure boot
      sbctl

      libsForQt5.qt5.qtwayland

      # nix package database
      nix-index
      nixos-generators

      # commit hooks
      pre-commit

      # proc info
      acpi

      # pci info
      pciutils
      usbutils

      # better make for general tasks
      just

      screenshare
      fullscreen

      # keyboards
      qmk
      vial
      via

      # theme related
      adwaita-icon-theme

      # kde-connect
      xdg-desktop-portal
      xdg-desktop-portal-wlr

      # bluetooth
      bluez
      ghostscript_headless
      wireguard-tools
      nixd
      zig
      zls
      ansible-language-server

      elk-to-svg

    ] ++ lib.optionals minimal [
      networkmanager
      curl
      git
      gnupg
      rsync
      ssh-to-age
      sops
      vim
      just
      sbctl
    ];

    nixpkgs.config.permittedInsecurePackages = lib.mkIf (!minimal) [
      "jitsi-meet-1.0.8043"
      "electron-29.4.6"
      "SDL_ttf-2.0.11"
    ];
  };
}
