{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.packages = lib.mkEnableOption "install packages";
  config = lib.mkIf config.swarselsystems.modules.packages {
    environment.systemPackages = with pkgs; [
      # yubikey packages
      gnupg
      yubikey-personalization
      yubikey-personalization-gui
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

    ];

    nixpkgs.config.permittedInsecurePackages = [
      "jitsi-meet-1.0.8043"
      "electron-29.4.6"
      "SDL_ttf-2.0.11"
    ];
  };
}
