{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    stable.teams-for-linux
    shellcheck
    dig
    docker
    postman
    rclone
    awscli2
    libguestfs-with-appliance
    stable.prometheus.cli
    tigervnc
  ];

  home.sessionVariables = {
    DOCUMENT_DIR_PRIV = lib.mkForce "${config.home.homeDirectory}/Documents/Private";
    DOCUMENT_DIR_WORK = lib.mkForce "${config.home.homeDirectory}/Documents/Work";
  };
  programs = {
    git.userEmail = "leon.schwarzaeugl@imba.oeaw.ac.at";

    zsh = {
      shellAliases = {
        dssh = "ssh -l dc_adm_schwarzaeugl";
        cssh = "ssh -l cl_adm_schwarzaeugl";
        wssh = "ssh -l ws_adm_schwarzaeugl";
      };
      cdpath = [
        "~/Documents/Work"
      ];
      dirHashes = {
        d = "$HOME/.dotfiles";
        w = "$HOME/Documents/Work";
        s = "$HOME/.dotfiles/secrets";
        pr = "$HOME/Documents/Private";
        ac = "$HOME/.ansible/collections/ansible_collections/vbc/linux/roles";
      };
    };

    ssh = {
      matchBlocks = {
        "uc" = {
          hostname = "uc.clip.vbc.ac.at";
          user = "stack";
        };
        "uc.stg" = {
          hostname = "uc.staging.clip.vbc.ac.at";
          user = "stack";
        };
        "uc.staging" = {
          hostname = "uc.staging.clip.vbc.ac.at";
          user = "stack";
        };
        "uc.dev" = {
          hostname = "uc.dev.clip.vbc.ac.at";
          user = "stack";
        };
        "cbe" = {
          hostname = "cbe.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "cbe.stg" = {
          hostname = "cbe.staging.clip.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "cbe.staging" = {
          hostname = "cbe.staging.clip.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "*.vbc.ac.at" = {
          user = "dc_adm_schwarzaeugl";
        };
      };
    };

    firefox = {
      profiles = {
        dc_adm = lib.recursiveUpdate
          {
            id = 1;
            settings = {
              "browser.startup.homepage" = "https://tower.vbc.ac.at";
            };
          }
          config.swarselsystems.firefox;
        cl_adm = lib.recursiveUpdate
          {
            id = 2;
            settings = {
              "browser.startup.homepage" = "https://portal.azure.com";
            };
          }
          config.swarselsystems.firefox;
        ws_adm = lib.recursiveUpdate { id = 3; } config.swarselsystems.firefox;
      };
    };

    chromium = {
      enable = true;
      package = pkgs.chromium;

      extensions = [
        # 1password
        "gejiddohjgogedgjnonbofjigllpkmbf"
        # dark reader
        "eimadpbcbfnmbkopoojfekhnkhdbieeh"
        # ublock origin
        "cjpalhdlnbpafiamejdnhcphjbkeiagm"
        # i still dont care about cookies
        "edibdbjcniadpccecjdfdjjppcpchdlm"
        # browserpass
        "naepdomgkenhinolocfifgehidddafch"
      ];
    };
  };

  xdg = {
    mimeApps = {
      defaultApplications = {
        "x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
      };
    };
    desktopEntries =
      let
        terminal = false;
        categories = [ "Application" ];
        icon = "firefox";
      in
      {
        firefox_dc = {
          name = "Firefox (dc_adm)";
          genericName = "Firefox dc";
          exec = "firefox -p dc_adm";
          inherit terminal categories icon;
        };

        firefox_ws = {
          name = "Firefox (ws_adm)";
          genericName = "Firefox ws";
          exec = "firefox -p ws_adm";
          inherit terminal categories icon;
        };

        firefox_cl = {
          name = "Firefox (cl_adm)";
          genericName = "Firefox cl";
          exec = "firefox -p cl_adm";
          inherit terminal categories icon;
        };

      };
  };

}
