{ pkgs, ... }:

{
  home.packages = with pkgs; [

    # audio stuff
    spek # spectrum analyzer
    losslessaudiochecker
    ffmpeg_5-full
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
    discord
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
    (pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-full
        dvisvgm dvipng# for preview and export as html
        wrapfig amsmath ulem hyperref capt-of;
    })

    # font stuff
    (nerdfonts.override { fonts = [ "FiraMono" "FiraCode" "NerdFontsSymbolsOnly" ]; })
    noto-fonts-emoji
    font-awesome_5
    noto-fonts
    noto-fonts-cjk-sans

    pass-fuzzel
    cura5
    cdw
    cdb
    bak
    timer
    e
    swarselcheck
    waybarupdate
    opacitytoggle
    fs-diff

    (pkgs.writeScriptBin "project" ''
      #! ${pkgs.bash}/bin/bash
      if [ "$1" == "rust" ]; then
      cp ~/.dotfiles/templates/rust_flake.nix ./flake.nix
      cp ~/.dotfiles/templates/toolchain.toml .
      elif [ "$1" == "cpp" ]; then
      cp ~/.dotfiles/templates/cpp_flake.nix ./flake.nix
      elif [ "$1" == "python" ]; then
      cp ~/.dotfiles/templates/py_flake.nix ./flake.nix
      elif [ "$1" == "cuda" ]; then
      cp ~/.dotfiles/templates/cu_flake.nix ./flake.nix
      elif [ "$1" == "other" ]; then
      cp ~/.dotfiles/templates/other_flake.nix ./flake.nix
      elif [ "$1" == "latex" ]; then
        if [ "$2" == "" ]; then
        echo "No filename specified, usage: 'project latex <NAME>'"
        exit 0
        fi
      cp ~/.dotfiles/templates/tex_standard.tex ./"$2".tex
      exit 0
      else
      echo "No valid argument given. Valid arguments are rust cpp python, cuda"
      exit 0
      fi
      echo "use flake" >> .envrc
      direnv allow
    '')






  ];
}
