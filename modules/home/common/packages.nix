{ config, lib, pkgs, ... }:

{
  config = {
    swarselsystems.enabledHomeModules = [ "packages" ];
    home.packages = with pkgs; [

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
      nixpkgs-fmt
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

    ] ++ lib.optionals (config.swarselsystems.isFullBuild && pkgs.stdenv.hostPlatform.isx86_64) [
      losslessaudiochecker
      cura-appimage
      zoom-us
    ] ++ lib.optionals config.swarselsystems.isFullBuild [

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
      (aspellWithDicts (dicts: with dicts; [ de en en-computers en-science ]))

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
      (texlive.combine {
        inherit (pkgs.texlive) scheme-full
          dvisvgm dvipng# for preview and export as html
          wrapfig amsmath ulem hyperref capt-of;
      })

      # font stuff
      cantarell-fonts
      nerd-fonts.fira-code
      (iosevka-bin.override { variant = "Aile"; })
      nerd-fonts.symbols-only
      noto-fonts-color-emoji
      font-awesome_5
    ];
  };
}
