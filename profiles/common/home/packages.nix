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

    # games
    lutris
    wine
    libudev-zero
    dwarfs
    fuse-overlayfs
    # steam
    # steam-run
    patchelf
    gamescope
    vulkan-tools
    moonlight-qt
    ns-usbloader

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

    # cura
    (
      let
        cura5 = appimageTools.wrapType2 rec {
          name = "cura5";
          version = "5.4.0";
          src = fetchurl {
            url = "https://github.com/Ultimaker/Cura/releases/download/${version}/UltiMaker-Cura-${version}-linux-modern.AppImage";
            hash = "sha256-QVv7Wkfo082PH6n6rpsB79st2xK2+Np9ivBg/PYZd74=";
          };
          extraPkgs = pkgs: with pkgs; [ ];
        };
      in
      writeScriptBin "cura" ''
        #! ${pkgs.bash}/bin/bash
        # AppImage version of Cura loses current working directory and treats all paths relateive to $HOME.
        # So we convert each of the files passed as argument to an absolute path.
        # This fixes use cases like `cd /path/to/my/files; cura mymodel.stl anothermodel.stl`.
        args=()
        for a in "$@"; do
            if [ -e "$a" ]; then
               a="$(realpath "$a")"
            fi
            args+=("$a")
        done
        exec "${cura5}/bin/cura5" "''${args[@]}"
      ''
    )

    #E: hides scratchpad depending on state, calls emacsclient for edit and then restores the scratchpad state
    (pkgs.writeShellScriptBin "e" ''
      bash ~/.dotfiles/scripts/editor_nowait.sh "$@"
    '')
    (pkgs.writeShellScriptBin "timer" ''
      sleep "$1"; while true; do spd-say "$2"; sleep 0.5; done;
    '')

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

    (pkgs.writeShellApplication {
      name = "pass-fuzzel";
      runtimeInputs = [ pkgs.pass pkgs.fuzzel ];
      text = ''
        shopt -s nullglob globstar

        typeit=0
        if [[ $# -ge 1 && $1 == "--type" ]]; then
          typeit=1
          shift
        fi

        export PASSWORD_STORE_DIR=~/.local/share/password-store
        prefix=''${PASSWORD_STORE_DIR-~/.local/share/password-store}
        password_files=( "$prefix"/**/*.gpg )
        password_files=( "''${password_files[@]#"$prefix"/}" )
        password_files=( "''${password_files[@]%.gpg}" )

        password=$(printf '%s\n' "''${password_files[@]}" | fuzzel --dmenu "$@")

        [[ -n $password ]] || exit

        if [[ $typeit -eq 0 ]]; then
          pass show -c "$password" &>/tmp/pass-fuzzel
        else
          pass show "$password" | { IFS= read -r pass; printf %s "$pass"; } | wtype -
        fi
        notify-send -u critical -a pass -t 1000 "Copied/Typed Password"
      '';
    })

    (pkgs.writeShellApplication {
      name = "pass-fuzzel-otp";
      runtimeInputs = [ pkgs.fuzzel (pkgs.pass.withExtensions (exts: [ exts.pass-otp ])) ];
      text = ''
        shopt -s nullglob globstar

        typeit=0
        if [[ $# -ge 1 && $1 == "--type" ]]; then
          typeit=1
          shift
        fi

        export PASSWORD_STORE_DIR=~/.local/share/password-store
        prefix=''${PASSWORD_STORE_DIR-~/.local/share/password-store}
        password_files=( "$prefix"/otp/**/*.gpg )
        password_files=( "''${password_files[@]#"$prefix"/}" )
        password_files=( "''${password_files[@]%.gpg}" )

        password=$(printf '%s\n' "''${password_files[@]}" | fuzzel --dmenu "$@")

        [[ -n $password ]] || exit

        if [[ $typeit -eq 0 ]]; then
          pass otp -c "$password" &>/tmp/pass-fuzzel
        else
          pass otp "$password" | { IFS= read -r pass; printf %s "$pass"; } | wtype -
        fi
        notify-send -u critical -a pass -t 1000 "Copied/Typed OTPassword"
      '';
    })

    (pkgs.writeShellApplication {
      name = "cdw";
      runtimeInputs = [ pkgs.fzf ];
      text = ''
        cd "$(git worktree list | fzf | awk '{print $1}')"
      '';
    })

    (pkgs.writeShellApplication {
      name = "cdb";
      runtimeInputs = [ pkgs.fzf ];
      text = ''
        git checkout "$(git branch --list | grep -v "^\*" | fzf | awk '{print $1}')"
      '';
    })

    (pkgs.writeShellApplication {
      name = "bak";
      text = ''
        cp "$1"{,.bak}
      '';
    })

  ];
}