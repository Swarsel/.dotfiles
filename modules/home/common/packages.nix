{ lib, config, pkgs, ... }:

{
  options.swarselmodules.packages = lib.mkEnableOption "packages settings";
  config = lib.mkIf config.swarselmodules.packages {
    home.packages = with pkgs; [

      # audio stuff
      spek # spectrum analyzer
      losslessaudiochecker
      ffmpeg_7-full
      flac
      mediainfo
      picard-tools
      audacity
      sox
      # stable.feishin # does not work with oauth2-proxy
      calibre

      # printing
      cups
      simple-scan
      cura-appimage

      # ssh login using idm
      opkssh

      # dict
      (aspellWithDicts (dicts: with dicts; [ de en en-computers en-science ]))

      # browser
      stable24_11.vieb
      mgba

      # utilities
      util-linux
      nmap
      lsof
      nvd
      nix-output-monitor
      hyprpicker # color picker
      findutils
      units
      vim
      sshfs
      fuse
      # ventoy
      poppler-utils
      vdhcoapp

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
      nixpkgs-review
      manix
      comma

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
      inkscape
      zoom-us
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
      stable.transmission_3
      mktorrent
      hugo

      # kyria
      qmk
      qmk-udev-rules

      # firefox related
      tridactyl-native

      # mako related
      mako
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
      psmisc # kill etc
      lm_sensors
      # jq # used for searching the i3 tree in check<xxx>.sh files

      # specifically needed for anki
      # mpv
      # anki-bin

      # dirvish file previews
      fd
      imagemagick
      # poppler
      ffmpegthumbnailer
      mediainfo
      gnutar
      unzip

      #nautilus
      nautilus
      xfce.tumbler
      libgsf

      # wayland stuff
      wtype
      wl-mirror
      wl-clipboard
      wf-recorder
      kanshi

      # screenshotting tools
      grim
      slurp

      # the following packages are used (in some way) by waybar
      # playerctl
      pavucontrol
      # stable.pamixer
      # gnome.gnome-clocks
      # wlogout
      # jdiskreport
      # monitor

      #keychain
      qalculate-gtk
      gcr # needed for gnome-secrets to work
      seahorse

      # sops-related
      sops
      ssh-to-age

      # mail related packages
      mu

      # latex and related packages
      (texlive.combine {
        inherit (pkgs.texlive) scheme-full
          dvisvgm dvipng# for preview and export as html
          wrapfig amsmath ulem hyperref capt-of;
      })

      # font stuff
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      noto-fonts-color-emoji
      font-awesome_5
      noto-fonts
      noto-fonts-cjk-sans
    ];
  };
}
