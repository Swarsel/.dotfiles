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
  ];

  programs = {
    git.userEmail = "leon.schwarzaeugl@imba.oeaw.ac.at";

    zsh = {
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
        "uc-stg" = {
          hostname = "uc.staging.clip.vbc.ac.at";
          user = "stack";
        };
        "cbe" = {
          hostname = "cbe.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "cbe-stg" = {
          hostname = "cbe.staging.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "*.vbc.ac.at" = {
          user = "dc_adm_schwarzaeugl";
        };
      };
    };

    firefox = {
      profiles = {
        dc_adm = lib.recursiveUpdate { id = 1; } config.swarselsystems.firefox;
        cl_adm = lib.recursiveUpdate { id = 2; } config.swarselsystems.firefox;
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
