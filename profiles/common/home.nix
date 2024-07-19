{ config, pkgs, fetchFromGitHub, ... }:

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

  sops = {
    defaultSopsFile = "${config.home.homeDirectory}/.dotfiles/secrets/general/secrets.yaml";
    validateSopsFiles = false;
    secrets = {
      mrswarsel = { path = "/run/user/1000/secrets/mrswarsel"; };
      nautilus = { path = "/run/user/1000/secrets/nautilus"; };
      leon = { path = "/run/user/1000/secrets/leon"; };
      swarselmail = { path = "/run/user/1000/secrets/swarselmail"; };
      caldav = { path = "${config.home.homeDirectory}/.emacs.d/.caldav"; };
    };
  };

  programs.ssh = {
    enable = true;
    forwardAgent = true;
    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
    matchBlocks = {
      "nginx" = {
        hostname = "192.168.1.14";
        user = "root";
      };
      "jellyfin" = {
        hostname = "192.168.1.16";
        user = "root";
      };
      "pfsense" = {
        hostname = "192.168.1.1";
        user = "root";
      };
      "proxmox" = {
        hostname = "192.168.1.2";
        user = "root";
      };
      "transmission" = {
        hostname = "192.168.1.6";
        user = "root";
      };
      "fetcher" = {
        hostname = "192.168.1.7";
        user = "root";
      };
      "omv" = {
        hostname = "192.168.1.3";
        user = "root";
      };
      "webbot" = {
        hostname = "192.168.1.11";
        user = "root";
      };
      "nextcloud" = {
        hostname = "192.168.1.5";
        user = "root";
      };
      "sound" = {
        hostname = "192.168.1.13";
        user = "root";
      };
      "spotify" = {
        hostname = "192.168.1.17";
        user = "root";
      };
      "wordpress" = {
        hostname = "192.168.1.9";
        user = "root";
      };
      "turn" = {
        hostname = "192.168.1.18";
        user = "root";
      };
      "hugo" = {
        hostname = "192.168.1.19";
        user = "root";
      };
      "matrix" = {
        hostname = "192.168.1.23";
        user = "root";
      };
      "scroll" = {
        hostname = "192.168.1.22";
        user = "root";
      };
      "minecraft" = {
        hostname = "130.61.119.129";
        user = "opc";
      };
      "sync" = {
        hostname = "193.122.53.173";
        user = "root"; #this is a oracle vm server but needs root due to nixos-infect
      };
      "songdiver" = {
        hostname = "89.168.100.65";
        user = "ubuntu";
      };
      "pkv" = {
        hostname = "46.232.248.161";
        user = "root";
      };
      "efficient" = {
        hostname = "g0.complang.tuwien.ac.at";
        forwardAgent = true;
        user = "ep01427399";
      };
    };
  };

  stylix.targets.emacs.enable = false;

  xdg.desktopEntries = {

    cura = {
      name = "Ultimaker Cura";
      genericName = "Cura";
      exec = "cura";
      terminal = false;
      categories = [ "Application" ];
    };

    anki = {
      name = "Anki Flashcards";
      genericName = "Anki";
      exec = "anki";
      terminal = false;
      categories = [ "Application" ];
    };

    # schlidichat = {
    #   name = "SchildiChat Matrix Client";
    #   genericName = "SchildiChat";
    #   exec = "schildichat-desktop -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
    #   terminal = false;
    #   categories = [ "Application"];
    # };

    element = {
      name = "Element Matrix Client";
      genericName = "Element";
      exec = "element-desktop -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
      terminal = false;
      categories = [ "Application" ];
    };

    emacsclient-newframe = {
      name = "Emacs (Client, New Frame)";
      genericName = "Emacs (Client, New Frame)";
      exec = "emacsclient -r %u";
      icon = "emacs";
      terminal = false;
      categories = [ "Development" "TextEditor" ];
    };

  };

  home.file = {
    "init.el" = {
      source = ../../programs/emacs/init.el;
      target = ".emacs.d/init.el";
    };
    "early-init.el" = {
      source = ../../programs/emacs/early-init.el;
      target = ".emacs.d/early-init.el";
    };
    # on NixOS, Emacs does not find the aspell dicts easily. Write the configuration manually
    ".aspell.conf" = {
      source = ../../programs/config/.aspell.conf;
      target = ".aspell.conf";
    };
    ".gitmessage" = {
      source = ../../programs/git/.gitmessage;
      target = ".gitmessage";
    };
  };

  xdg.configFile = {
    "tridactyl/tridactylrc".source = ../../programs/firefox/tridactyl/tridactylrc;
    "tridactyl/themes/base16-codeschool.css".source = ../../programs/firefox/tridactyl/themes/base16-codeschool.css;
  };

  home.sessionVariables = {
    EDITOR = "bash ~/.dotfiles/scripts/editor.sh";
  };

  programs = {
    bottom.enable = true;
    imv.enable = true;
    sioyek.enable = true;
    bat.enable = true;
    carapace.enable = true;
    wlogout.enable = true;
    swayr.enable = true;
    yt-dlp.enable = true;
    mpv.enable = true;
    jq.enable = true;
    ripgrep.enable = true;
    pandoc.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
  };

  programs.nix-index =
    let
      command-not-found = pkgs.runCommandLocal "command-not-found.sh" { } ''
        mkdir -p $out/etc/profile.d
        substitute ${../../scripts/command-not-found.sh}                  \
          $out/etc/profile.d/command-not-found.sh             \
          --replace @nix-locate@ ${pkgs.nix-index}/bin/nix-locate \
          --replace @tput@ ${pkgs.ncurses}/bin/tput
      '';
    in
    {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "nix-index";
        paths = [ command-not-found ];
      };
    };

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    extraOptions = [
      "-l"
      "--group-directories-first"
    ];
  };

  programs.git = {
    enable = true;
    aliases = {
      a = "add";
      c = "commit";
      cl = "clone";
      co = "checkout";
      b = "branch";
      i = "init";
      m = "merge";
      s = "status";
      r = "restore";
      p = "pull";
      pp = "push";
    };
    signing = {
      key = "0x76FD3810215AE097";
      signByDefault = true;
    };
    userEmail = "leon.schwarzaeugl@gmail.com";
    userName = "Swarsel";
    difftastic.enable = true;
    lfs.enable = true;
    includes = [
      {
        contents = {
          github = {
            user = "Swarsel";
          };
          commit = {
            template = "~/.gitmessage";
          };
        };
      }
    ];
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        layer = "overlay";
        lines = "10";
        width = "40";
      };
      border.radius = "0";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$character";
      right_format = "$all";
      command_timeout = 3000;

      directory.substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = " ";
        "Pictures" = " ";
      };

      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };

      character = {
        success_symbol = "[λ](bold green)";
        error_symbol = "[λ](bold red)";
      };

      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      conda.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fossil_branch.symbol = " ";
      git_branch.symbol = " ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";

      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Windows = "󰍲 ";
      };

      package.symbol = "󰏗 ";
      pijul_channel.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = " ";
      scala.symbol = " ";
    };
  };

  programs.kitty = {
    enable = true;
    keybindings = {
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
      "ctrl+shift+home" = "no_op";
      "ctrl+shift+end" = "no_op";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      hg = "history | grep";
      hmswitch = "cd ~/.dotfiles; home-manager --flake .#$(whoami)@$(hostname) switch; cd -;";
      nswitch = "cd ~/.dotfiles; sudo nixos-rebuild --flake .#$(hostname) switch; cd -;";
      edithome = "bash ~/.dotfiles/scripts/editor.sh ~/.dotfiles/Nix.org";
      magit = "emacsclient -nc -e \"(magit-status)\"";
      config = "git --git-dir=$HOME/.cfg/ --work-tree=$HOME";
      g = "git";
      c = "git --git-dir=$HOME/.dotfiles/.git --work-tree=$HOME/.dotfiles/";
      passpush = "cd ~/.local/share/password-store; git add .; git commit -m 'pass file changes'; git push; cd -;";
      passpull = "cd ~/.local/share/password-store; git pull; cd -;";
      hotspot = "nmcli connection up local; nmcli device wifi hotspot;";
      cd = "z";
      cdr = "cd \"$( (find /home/swarsel/Documents/GitHub -maxdepth 1 && echo /home/swarsel/.dotfiles) | fzf )\"";
    };
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autocd = false;
    cdpath = [
      "~/.dotfiles"
      # "~/Documents/GitHub"
    ];
    defaultKeymap = "emacs";
    dirHashes = {
      dl = "$HOME/Downloads";
      gh = "$HOME/Documents/GitHub";
    };
    history = {
      expireDuplicatesFirst = true;
      path = "$HOME/.histfile";
      save = 10000;
      size = 10000;
    };
    historySubstringSearch.enable = true;
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
      }
    ];
    initExtra = ''
      bindkey "^[[1;5D" backward-word
      bindkey "^[[1;5C" forward-word
    '';
  };

  programs.mbsync = {
    enable = true;
  };
  # this is needed so that mbsync can use the passwords from sops
  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];

  programs.msmtp = {
    enable = true;
  };

  programs.mu = {
    enable = true;
  };

  accounts.email = {
    maildirBasePath = "Mail";
    accounts.leon = {
      primary = true;
      address = "leon.schwarzaeugl@gmail.com";
      userName = "leon.schwarzaeugl@gmail.com";
      realName = "Leon Schwarzäugl";
      passwordCommand = "cat ${config.sops.secrets.leon.path}";
      # passwordCommand = "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.local/share/password-store/mail/mbsync/leon.schwarzaeugl@gmail.com.gpg";
      gpg = {
        key = "0x76FD3810215AE097";
        signByDefault = true;
      };
      imap.host = "imap.gmail.com";
      smtp.host = "smtp.gmail.com";
      mu.enable = true;
      msmtp = {
        enable = true;
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail" ];
        extraConfig = {
          channel = {
            Sync = "All";
          };
          account = {
            Timeout = 120;
            PipelineDepth = 1;
          };
        };
      };
    };

    accounts.swarsel = {
      address = "leon@swarsel.win";
      userName = "8227dc594dd515ce232eda1471cb9a19";
      realName = "Leon Schwarzäugl";
      passwordCommand = "cat ${config.sops.secrets.swarselmail.path}";
      smtp = {
        host = "in-v3.mailjet.com";
        port = 587;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      mu.enable = false;
      msmtp = {
        enable = true;
      };
      mbsync = {
        enable = false;
      };
    };

    accounts.nautilus = {
      primary = false;
      address = "nautilus.dw@gmail.com";
      userName = "nautilus.dw@gmail.com";
      realName = "Nautilus";
      passwordCommand = "cat ${config.sops.secrets.nautilus.path}";
      # passwordCommand = "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.local/share/password-store/mail/mbsync/nautilus.dw@gmail.com.gpg";
      imap.host = "imap.gmail.com";
      smtp.host = "smtp.gmail.com";
      msmtp.enable = true;
      mu.enable = true;
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail" ];
        extraConfig = {
          channel = {
            Sync = "All";
          };
          account = {
            Timeout = 120;
            PipelineDepth = 1;
          };
        };
      };
    };
    accounts.mrswarsel = {
      primary = false;
      address = "mrswarsel@gmail.com";
      userName = "mrswarsel@gmail.com";
      realName = "Swarsel";
      # passwordCommand = "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.local/share/password-store/mail/mbsync/mrswarsel@gmail.com.gpg";
      passwordCommand = "cat ${config.sops.secrets.mrswarsel.path}";
      imap.host = "imap.gmail.com";
      smtp.host = "smtp.gmail.com";
      msmtp.enable = true;
      mu.enable = true;
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail" ];
        extraConfig = {
          channel = {
            Sync = "All";
          };
          account = {
            Timeout = 120;
            PipelineDepth = 1;
          };
        };
      };
    };
  };

  # enable emacs overlay for bleeding edge features
  # also read init.el file and install use-package packages
  programs.emacs = {
    enable = true;
    package = pkgs.emacsWithPackagesFromUsePackage {
      config = ../../programs/emacs/init.el;
      package = pkgs.emacs-pgtk;
      alwaysEnsure = true;
      alwaysTangle = true;
      extraEmacsPackages = epkgs: [
        epkgs.mu4e
        epkgs.use-package
        # epkgs.lsp-bridge
        epkgs.doom-themes

        # build the rest of the packages myself
        # org-calfw is severely outdated on MELPA and throws many warnings on emacs startup
        # build the package from the haji-ali fork, which is well-maintained
        (epkgs.trivialBuild rec {
          pname = "calfw";
          version = "1.0.0-20231002";
          src = pkgs.fetchFromGitHub {
            owner = "haji-ali";
            repo = "emacs-calfw";
            rev = "bc99afee611690f85f0cd0bd33300f3385ddd3d3";
            hash = "sha256-0xMII1KJhTBgQ57tXJks0ZFYMXIanrOl9XyqVmu7a7Y=";
          };
          packageRequires = [ epkgs.howm ];
        })

        (epkgs.trivialBuild rec {
          pname = "fast-scroll";
          version = "1.0.0-20191016";
          src = pkgs.fetchFromGitHub {
            owner = "ahungry";
            repo = "fast-scroll";
            rev = "3f6ca0d5556fe9795b74714304564f2295dcfa24";
            hash = "sha256-w1wmJW7YwXyjvXJOWdN2+k+QmhXr4IflES/c2bCX3CI=";
          };
          packageRequires = [ ];
        })

      ];
    };
  };

  programs.waybar = {

    enable = true;
    # systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "sway/workspaces" "custom/outer-right-arrow-dark" "sway/window" ];
        modules-center = [ "sway/mode" "custom/configwarn" ];
        "sway/mode" = {
          format = "<span style=\"italic\" font-weight=\"bold\">{}</span>";
        };

        "custom/configwarn" = {
          exec = "bash ~/.dotfiles/scripts/checkconfigstatus.sh";
          interval = 60;
        };

        "group/hardware" = {
          orientation = "inherit";
          drawer = {
            "transition-left-to-right" = false;
          };
          modules = [
            "tray"
            "temperature"
            "power-profiles-daemon"
            "custom/left-arrow-light"
            "disk"
            "custom/left-arrow-dark"
            "memory"
            "custom/left-arrow-light"
            "cpu"
            "custom/left-arrow-dark"
          ];
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            "default" = "";
            "performance" = "";
            "balanced" = "";
            "power-saver" = "";
          };
        };

        temperature = {
          critical-threshold = 80;
          format-critical = " {temperatureC}°C";
          format = " {temperatureC}°C";

        };

        mpris = {
          format = "{player_icon} {title} <small>[{position}/{length}]</small>";
          format-paused = "{player_icon}  <i>{title} <small>[{position}/{length}]</small></i>";
          player-icons = {
            "default" = "▶ ";
            "mpv" = "🎵 ";
            "spotify" = " ";
          };
          status-icons = {
            "paused" = " ";
          };
          interval = 1;
          title-len = 20;
          artist-len = 20;
          album-len = 10;
        };
        "custom/left-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/outer-left-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/left-arrow-light" = {
          format = "";
          tooltip = false;
        };
        "custom/right-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/outer-right-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/right-arrow-light" = {
          format = "";
          tooltip = false;
        };
        "sway/workspaces" = {
          disable-scroll = true;
          format = "{name}";
        };

        "clock#1" = {
          min-length = 8;
          interval = 1;
          format = "{:%H:%M:%S}";
          # on-click-right= "gnome-clocks";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "clock#2" = {
          format = "{:%d. %B %Y}";
          # on-click-right= "gnome-clocks";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = "{icon} {volume:2}%";
          format-bluetooth = "{icon} {volume}%";
          format-muted = "MUTE";
          format-icons = {
            headphones = "";
            default = [
              ""
              ""
            ];
          };
          scroll-step = 1;
          on-click = "pamixer -t";
          on-click-right = "pavucontrol";
        };
        memory = {
          interval = 5;
          format = " {}%";
          tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G\nSwap: {swapUsed}G/{swapTotal}G";
        };
        cpu = {
          min-length = 6;
          interval = 5;
          format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
          # on-click-right= "com.github.stsdc.monitor";
          on-click-right = "kitty -o confirm_os_window_close=0 btm";

        };
        battery = {
          states = {
            "warning" = 60;
            "error" = 30;
            "critical" = 15;
          };
          interval = 5;
          format = "{icon} {capacity}%";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          on-click-right = "wlogout -p layer-shell";
        };
        disk = {
          interval = 30;
          format = "Disk {percentage_used:2}%";
          path = "/";
          states = {
            "warning" = 80;
            "critical" = 90;
          };
          tooltip-format = "{used} used out of {total} on {path} ({percentage_used}%)\n{free} free on {path} ({percentage_free}%)";
        };
        tray = {
          icon-size = 20;
        };
        network = {
          interval = 5;
          format-wifi = "{signalStrength}% ";
          format-ethernet = "";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format-ethernet = "{ifname} via {gwaddr}: {essid} {ipaddr}/{cidr}\n\n⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
          tooltip-format-wifi = "{ifname} via {gwaddr}: {essid} {ipaddr}/{cidr} \n{signaldBm}dBm @ {frequency}MHz\n\n⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
        };
      };
    };
    style = builtins.readFile ../../programs/waybar/style.css;
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      nativeMessagingHosts = [
        pkgs.tridactyl-native
        pkgs.browserpass
        pkgs.plasma5Packages.plasma-browser-integration
      ];
    };
    policies = {
      CaptivePortal = false;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFirefoxAccounts = false;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      EnableTrackingProtection = true;
    };
    profiles.default = {
      isDefault = true;
      userChrome = builtins.readFile ../../programs/firefox/chrome/userChrome.css;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        tridactyl
        browserpass
        clearurls
        darkreader
        enhancer-for-youtube
        istilldontcareaboutcookies
        translate-web-pages
        ublock-origin
        reddit-enhancement-suite
        pushbullet
        sponsorblock
        web-archives
        single-file
        widegithub
        enhanced-github
        unpaywall
        don-t-fuck-with-paste
        plasma-integration
      ];

      search.engines = {
        "Nix Packages" = {
          urls = [{
            template = "https://search.nixos.org/packages";
            params = [
              { name = "type"; value = "packages"; }
              { name = "query"; value = "{searchTerms}"; }
            ];
          }];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@np" ];
        };

        "NixOS Wiki" = {
          urls = [{
            template = "https://nixos.wiki/index.php?search={searchTerms}";
          }];
          iconUpdateURL = "https://nixos.wiki/favicon.png";
          updateInterval = 24 * 60 * 60 * 1000; # every day
          definedAliases = [ "@nw" ];
        };

        "NixOS Options" = {
          urls = [{
            template = "https://search.nixos.org/options";
            params = [
              { name = "query"; value = "{searchTerms}"; }
            ];
          }];

          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@no" ];
        };

        "Home Manager Options" = {
          urls = [{
            template = "https://home-manager-options.extranix.com/";
            params = [
              { name = "query"; value = "{searchTerms}"; }
            ];
          }];

          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@hm" "@ho" "@hmo" ];
        };

        "Google".metaData.alias = "@g";
      };
      search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
    };
  };

  services.gnome-keyring = {
    enable = true;
  };

  services.mbsync = {
    enable = true;
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  services.syncthing = {
    enable = true;
    tray = {
      enable = false; # we enable this by installing the syncthingtray package instead, it works better.
    };
  };

  services.emacs = {
    enable = true;
    # socketActivation.enable = false;
    # startWithUserSession = "graphical";
  };

  services.mako = {
    enable = true;
    # backgroundColor = "#2e3440";
    # borderColor = "#88c0d0";
    borderRadius = 15;
    borderSize = 1;
    defaultTimeout = 5000;
    height = 150;
    icons = true;
    ignoreTimeout = true;
    layer = "overlay";
    maxIconSize = 64;
    sort = "-time";
    width = 300;
    # font = "monospace 10";
    extraConfig = "[urgency=low]
border-color=#cccccc
[urgency=normal]
border-color=#d08770
[urgency=high]
border-color=#bf616a
default-timeout=3000
[category=mpd]
default-timeout=2000
group-by=category
";
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false; # delete this line once SwayFX is fixed upstream
    package = pkgs.swayfx;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    wrapperFeatures.gtk = true;
    config = rec {
      modifier = "Mod4";
      terminal = "kitty";
      menu = "fuzzel";
      bars = [{ command = "waybar"; }];
      keybindings =
        let
          inherit (config.wayland.windowManager.sway.config) modifier;
        in
        {
          "${modifier}+q" = "kill";
          "${modifier}+f" = "exec firefox";
          "${modifier}+Space" = "exec fuzzel";
          "${modifier}+Shift+Space" = "floating toggle";
          "${modifier}+e" = "exec emacsclient -nquc -a emacs -e \"(dashboard-open)\"";
          "${modifier}+Shift+m" = "exec emacsclient -nquc -a emacs -e \"(mu4e)\"";
          "${modifier}+Shift+c" = "exec emacsclient -nquc -a emacs -e \"(swarsel/open-calendar)\"";
          "${modifier}+Shift+s" = "exec \"bash ~/.dotfiles/scripts/checkspotify.sh\"";
          "${modifier}+m" = "exec \"bash ~/.dotfiles/scripts/checkspotifytui.sh\"";
          "${modifier}+x" = "exec \"bash ~/.dotfiles/scripts/checkkitty.sh\"";
          "${modifier}+d" = "exec \"bash ~/.dotfiles/scripts/checkdiscord.sh\"";
          "${modifier}+Shift+r" = "exec \"bash ~/.dotfiles/scripts/restart.sh\"";
          "${modifier}+Shift+t" = "exec \"bash ~/.dotfiles/scripts/toggle_opacity.sh\"";
          "${modifier}+Shift+F12" = "move scratchpad";
          "${modifier}+F12" = "scratchpad show";
          "${modifier}+c" = "exec qalculate-gtk";
          "${modifier}+p" = "exec pass-fuzzel";
          "${modifier}+o" = "exec pass-fuzzel-otp";
          "${modifier}+Shift+p" = "exec pass-fuzzel --type";
          "${modifier}+Shift+o" = "exec pass-fuzzel-otp --type";
          "${modifier}+Escape" = "mode $exit";
          # "${modifier}+Shift+Escape" = "exec com.github.stsdc.monitor";
          "${modifier}+Shift+Escape" = "exec kitty -o confirm_os_window_close=0 btm";
          "${modifier}+s" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
          "${modifier}+i" = "exec \"bash ~/.dotfiles/scripts/startup.sh\"";
          "${modifier}+1" = "workspace 1:一";
          "${modifier}+Shift+1" = "move container to workspace 1:一";
          "${modifier}+2" = "workspace 2:二";
          "${modifier}+Shift+2" = "move container to workspace 2:二";
          "${modifier}+3" = "workspace 3:三";
          "${modifier}+Shift+3" = "move container to workspace 3:三";
          "${modifier}+4" = "workspace 4:四";
          "${modifier}+Shift+4" = "move container to workspace 4:四";
          "${modifier}+5" = "workspace 5:五";
          "${modifier}+Shift+5" = "move container to workspace 5:五";
          "${modifier}+6" = "workspace 6:六";
          "${modifier}+Shift+6" = "move container to workspace 6:六";
          "${modifier}+7" = "workspace 7:七";
          "${modifier}+Shift+7" = "move container to workspace 7:七";
          "${modifier}+8" = "workspace 8:八";
          "${modifier}+Shift+8" = "move container to workspace 8:八";
          "${modifier}+9" = "workspace 9:九";
          "${modifier}+Shift+9" = "move container to workspace 9:九";
          "${modifier}+0" = "workspace 10:十";
          "${modifier}+Shift+0" = "move container to workspace 10:十";
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "${modifier}+Left" = "focus left";
          "${modifier}+Right" = "focus right";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Shift+Left" = "move left 40px";
          "${modifier}+Shift+Right" = "move right 40px";
          "${modifier}+Shift+Down" = "move down 40px";
          "${modifier}+Shift+Up" = "move up 40px";
          "${modifier}+h" = "focus left";
          "${modifier}+l" = "focus right";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+Shift+h" = "move left 40px";
          "${modifier}+Shift+l" = "move right 40px";
          "${modifier}+Shift+j" = "move down 40px";
          "${modifier}+Shift+k" = "move up 40px";
          "${modifier}+Ctrl+Shift+c" = "reload";
          "${modifier}+Shift+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
          "${modifier}+r" = "mode resize";
          "${modifier}+Return" = "exec kitty";
        };
      modes = {
        resize = {
          Down = "resize grow height 10 px or 10 ppt";
          Escape = "mode default";
          Left = "resize shrink width 10 px or 10 ppt";
          Return = "mode default";
          Right = "resize grow width 10 px or 10 ppt";
          Up = "resize shrink height 10 px or 10 ppt";
        };
      };
      defaultWorkspace = "workspace 1:一";
      startup = [
        { command = "kitty -T kittyterm"; }
        { command = "sleep 60; kitty -T spotifytui -o confirm_os_window_close=0 spotify_player"; }
      ];
      window = {
        border = 1;
        titlebar = false;
      };
      assigns = {
        "1:一" = [{ app_id = "firefox"; }];
      };
      floating = {
        border = 1;
        criteria = [
          { title = "^Picture-in-Picture$"; }
          { app_id = "qalculate-gtk"; }
          { app_id = "org.gnome.clocks"; }
          { app_id = "com.github.stsdc.monitor"; }
          { app_id = "blueman"; }
          { app_id = "pavucontrol"; }
          { app_id = "syncthingtray"; }
          { title = "Syncthing Tray"; }
          { app_id = "SchildiChat"; }
          { app_id = "Element"; }
          { app_id = "com.nextcloud.desktopclient.nextcloud"; }
          { app_id = "gnome-system-monitor"; }
          { title = "(?:Open|Save) (?:File|Folder|As)"; }
          { title = "^Add$"; }
          { title = "com-jgoodies-jdiskreport-JDiskReport"; }
          { app_id = "discord"; }
          { window_role = "pop-up"; }
          { window_role = "bubble"; }
          { window_role = "dialog"; }
          { window_role = "task_dialog"; }
          { window_role = "menu"; }
          { window_role = "Preferences"; }
        ];
        titlebar = false;
      };
      window = {
        commands = [
          {
            command = "opacity 0.95";
            criteria = {
              class = ".*";
            };
          }
          {
            command = "opacity 1";
            criteria = {
              app_id = "Gimp-2.10";
            };
          }
          {
            command = "opacity 0.99";
            criteria = {
              app_id = "firefox";
            };
          }
          {
            command = "sticky enable, shadows enable";
            criteria = {
              title = "^Picture-in-Picture$";
            };
          }
          {
            command = "opacity 0.8, sticky enable, border normal, move container to scratchpad";
            criteria = {
              title = "^kittyterm$";
            };
          }
          {
            command = "opacity 0.95, sticky enable, border normal, move container to scratchpad";
            criteria = {
              title = "^spotifytui$";
            };
          }
          # {
          #   command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
          #   criteria = {
          #     app_id="^$";
          #     class="^$";
          # };
          # }
          {

            command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
            criteria = {
              class = "Spotify";
            };
          }
          {
            command = "sticky enable";
            criteria = {
              app_id = "discord";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, sticky enable";
            criteria = {
              class = "Element";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, sticky enable";
            criteria = {
              app_id = "SchildiChat";
            };
          }
        ];
      };
      gaps = {
        inner = 5;
      };
    };
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox";
      export ANKI_WAYLAND=1;
      export OBSIDIAN_USE_WAYLAND=1;
    '';
    # extraConfigEarly = "
    # exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
    # exec hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    # ";
    extraConfig =
      let
        inherit (config.wayland.windowManager.sway.config) modifier;
        swayfxSettings = "
        blur enable
        blur_xray disable
        blur_passes 1
        blur_radius 1
        shadows enable
        corner_radius 2
        titlebar_separator disable
        default_dim_inactive 0.02
    ";
      in
      "
      exec_always autotiling
      set $exit \"exit: [s]leep, [p]oweroff, [r]eboot, [l]ogout\"
      mode $exit {

          bindsym --to-code {
              s exec \"systemctl suspend\", mode \"default\"
              p exec \"systemctl poweroff\"
              r exec \"systemctl reboot\"
              l exec \"swaymsg exit\"

              Return mode \"default\"
              Escape mode \"default\"
              ${modifier}+x mode \"default\"
          }
      }

      exec systemctl --user import-environment

      ${swayfxSettings}

      ";
  };

}
