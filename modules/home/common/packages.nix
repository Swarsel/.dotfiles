{ lib, config, pkgs, ... }:

{
  options.swarselsystems.modules.packages = lib.mkEnableOption "packages settings";
  config = lib.mkIf config.swarselsystems.modules.packages {
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

      # dict
      (aspellWithDicts (dicts: with dicts; [ de en en-computers en-science ]))

      # browser
      vieb
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
      poppler_utils
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
      gimp
      inkscape
      zoom-us
      # nomacs
      libreoffice-qt
      xournalpp
      obsidian
      spotify
      vesktop # discord client
      nextcloud-client
      spotify-player
      element-desktop
      nicotine-plus
      stable.transmission_3
      mktorrent
      hexchat
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
      anki-bin

      # dirvish file previews
      fd
      imagemagick
      # poppler
      ffmpegthumbnailer
      mediainfo
      gnutar
      unzip

      #nautilus
      stable.nautilus
      xfce.tumbler
      libgsf

      # wayland stuff
      wtype
      wl-clipboard
      stable.wl-mirror
      wf-recorder
      kanshi

      # screenshotting tools
      grim
      slurp

      # the following packages are used (in some way) by waybar
      # playerctl
      stable.pavucontrol
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
      noto-fonts-emoji
      font-awesome_5
      noto-fonts
      noto-fonts-cjk-sans
    ];
  };
}
