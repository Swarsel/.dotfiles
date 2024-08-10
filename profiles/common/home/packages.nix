{ pkgs, ... }:

{
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
    google-chrome

    # printing
    cups
    simple-scan

    # dict
    (aspellWithDicts (dicts: with dicts; [ de en en-computers en-science ]))

    # utilities
    util-linux
    nmap
    lsof
    nvd

    # nix
    alejandra
    nixpkgs-fmt
    deadnix
    statix
    nix-tree

    # local file sharing
    wormhole-rs

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
    stable.nextcloud-client
    spotify-player
    element-desktop-wayland
    nicotine-plus
    stable.transmission
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
    samba
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
    poppler
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
    wl-clipboard
    wl-mirror

    # screenshotting tools
    grim
    slurp

    # the following packages are used (in some way) by waybar
    playerctl
    pavucontrol
    pamixer
    # gnome.gnome-clocks
    # wlogout
    # jdiskreport
    syncthingtray
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
    nerdfonts # has overrides
    noto-fonts-emoji
    font-awesome_5
    noto-fonts
    noto-fonts-cjk-sans
  ];
}
