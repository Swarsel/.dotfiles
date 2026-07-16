{
  flake.modules = {
    homeManager.packages =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        config = {
          swarselsystems.enabledHomeModules = [ "packages" ];
          home.packages =
            with pkgs;
            [

              vim
              util-linux
              findutils
              fd
              unzip
              gnutar
              psmisc # kill etc
              lsof
              hyprpicker # color picker
              wl-mirror

              # cache
              attic-client

              # mail related packages
              mu

              # sops-related
              sops
              ssh-to-age

              nvd
              nix-output-monitor

              # nix
              alejandra
              nixfmt
              deadnix
              statix
              nix-tree
              nix-diff
              nix-visualize
              nix-init
              nix-inspect
              (nixpkgs-review.override { nix = config.nix.package; })
              manix

              #nautilus
              nautilus
              tumbler
              libgsf

              claude-code

            ]
            ++ lib.optionals (config.swarselsystems.isFullBuild && pkgs.stdenv.hostPlatform.isx86_64) [
              losslessaudiochecker
              cura-appimage
              zoom-us
            ]
            ++ lib.optionals config.swarselsystems.isFullBuild [

              # audio stuff
              spek # spectrum analyzer
              ffmpeg_7-full
              flac
              mediainfo
              picard-tools
              audacity
              sox
              calibre

              # printing
              cups
              simple-scan

              # ssh login using idm
              opkssh

              # dict
              (aspellWithDicts (
                dicts: with dicts; [
                  de
                  en
                  en-computers
                  en-science
                ]
              ))

              # browser
              vieb
              mgba

              # utilities
              nmap
              units
              sshfs
              fuse
              # ventoy
              poppler-utils

              # shellscripts
              shfmt

              # local file sharing
              wormhole-rs
              croc

              # b2 backup @backblaze
              restic

              # "big" programs
              # obs-studio
              gimp
              stable.inkscape
              # nomacs
              libreoffice-qt
              xournalpp
              # obsidian
              # spotify
              # vesktop # discord client
              # nextcloud-client # enables a systemd service that I do not want
              # spotify-player
              # element-desktop

              nicotine-plus
              transmission_3
              mktorrent
              hugo

              # kyria
              qmk
              qmk-udev-rules

              # firefox related
              tridactyl-native

              # mako related
              # mako
              libnotify

              # general utilities
              unrar
              # samba
              cifs-utils
              zbar # qr codes
              readline
              autotiling
              brightnessctl
              libappindicator-gtk3
              sqlite
              speechd
              networkmanagerapplet
              lm_sensors
              # jq # used for searching the i3 tree in check<xxx>.sh files

              # specifically needed for anki
              # mpv
              # anki-bin

              # dirvish file previews
              imagemagick
              # poppler
              ffmpegthumbnailer

              # wayland stuff
              wtype
              wl-clipboard
              wf-recorder
              kanshi

              # screenshotting tools
              grim
              slurp

              # the following packages are used (in some way) by waybar
              pavucontrol

              #keychain
              qalculate-gtk
              gcr # needed for gnome-secrets to work
              seahorse

              # latex and related packages
              texliveFull

              # font stuff
              cantarell-fonts
              nerd-fonts.fira-code
              (iosevka-bin.override { variant = "Aile"; })
              nerd-fonts.symbols-only
              noto-fonts-color-emoji
              font-awesome_5
            ];
        };
      };
    nixos.packages =
      {
        config,
        lib,
        pkgs,
        minimal,
        ...
      }:
      {
        config = {

          environment.systemPackages =
            with pkgs;
            lib.optionals (!minimal) (
              [
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
              ]
              ++ lib.optionals (config.swarselsystems.isFullBuild && pkgs.stdenv.hostPlatform.isx86_64) [
                # ledger packages
                ledger-live-desktop

                # keyboards
                vial
                via
              ]
              ++ lib.optionals config.swarselsystems.isFullBuild [
                # yubikey packages
                yubikey-personalization
                yubico-pam
                yubioath-flutter
                yubikey-touch-detector
                yubico-piv-tool
                cfssl
                pcsc-tools
                pcscliteWithPolkit.out

                # pinentry
                dbus
                # swaylock-effects
                syncthingtray-minimal
                swayosd

                qt5.qtwayland

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

                # kde-connect
                xdg-desktop-portal
                xdg-desktop-portal-gtk
                xdg-desktop-portal-wlr

                ghostscript_headless
                nixd
                zig
                zls

                elk-to-svg
              ]
            )
            ++ lib.optionals minimal [
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
      };
  };
}
