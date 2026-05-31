{ lib, pkgs, config, minimal, ... }:
{
  config = {

    environment.systemPackages = with pkgs; lib.optionals (!minimal)
      ([
        gnupg
        yubikey-manager

        # secure boot
        sbctl

        # better make for general tasks
        just

        # sops
        ssh-to-age
        sops

        # theme related
        adwaita-icon-theme

        # bluetooth
        bluez
        wireguard-tools
      ] ++ lib.optionals config.swarselsystems.isFullBuild [
        # yubikey packages
        yubikey-personalization
        yubico-pam
        yubioath-flutter
        yubikey-touch-detector
        yubico-piv-tool
        cfssl
        pcsc-tools
        pcscliteWithPolkit.out

        # ledger packages
        ledger-live-desktop

        # pinentry
        dbus
        # swaylock-effects
        syncthingtray-minimal
        swayosd

        libsForQt5.qt5.qtwayland

        nixos-generators

        # commit hooks
        pre-commit

        # proc info
        acpi

        # pci info
        pciutils
        usbutils

        # keyboards
        qmk
        vial
        via

        # kde-connect
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr

        ghostscript_headless
        nixd
        zig
        zls

        elk-to-svg
      ]) ++ lib.optionals minimal [
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
      # audacity?
      "mbedtls-2.28.10"
      # "qtwebengine-5.15.19"
    ];
  };
}
