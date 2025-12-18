{ self, config, pkgs, lib, vars, confLib, type, ... }:
let
  inherit (config.swarselsystems) homeDir mainUser;
  inherit (confLib.getConfig.repo.secrets.local.mail) allMailAddresses;
  inherit (confLib.getConfig.repo.secrets.local.work) mailAddress;

  certsSopsFile = self + /secrets/repo/certs.yaml;
in
{
  options.swarselmodules.optional-work = lib.swarselsystems.mkTrueOption;
  config = {
    home = {
      packages = with pkgs; [
        stable.teams-for-linux
        shellcheck
        dig
        docker
        postman
        # rclone
        libguestfs-with-appliance
        prometheus.cli
        tigervnc
        # openstackclient

        vscode
        dev.antigravity

        rustdesk-vbc
      ];
      sessionVariables = {
        AWS_CA_BUNDLE = confLib.getConfig.sops.secrets.harica-root-ca.path;
      };
    };
    systemd.user.sessionVariables = {
      DOCUMENT_DIR_WORK = lib.mkForce "${homeDir}/Documents/Work";
    } // lib.optionalAttrs (!config.swarselsystems.isPublic) {
      SWARSEL_MAIL_ALL = lib.mkForce allMailAddresses;
      SWARSEL_MAIL_WORK = lib.mkForce mailAddress;
    };

    accounts.email.accounts.work =
      let
        inherit (confLib.getConfig.repo.secrets.local.work) mailName;
      in
      {
        primary = false;
        address = mailAddress;
        userName = mailAddress;
        realName = mailName;
        passwordCommand = "pizauth show work";
        imap = {
          host = "outlook.office365.com";
          port = 993;
          tls.enable = true; # SSL/TLS
        };
        smtp = {
          host = "outlook.office365.com";
          port = 587;
          tls = {
            enable = true; # SSL/TLS
            useStartTls = true;
          };
        };
        thunderbird = {
          enable = true;
          profiles = [ "default" ];
          settings = id: {
            "mail.smtpserver.smtp_${id}.authMethod" = 10; # oauth
            "mail.server.server_${id}.authMethod" = 10; # oauth
            # "toolkit.telemetry.enabled" = false;
            # "toolkit.telemetry.rejected" = true;
            # "toolkit.telemetry.prompted" = 2;
          };
        };
        msmtp = {
          enable = true;
          extraConfig = {
            auth = "xoauth2";
            host = "outlook.office365.com";
            protocol = "smtp";
            port = "587";
            tls = "on";
            tls_starttls = "on";
            from = "${mailAddress}";
            user = "${mailAddress}";
            passwordeval = "pizauth show work";
          };
        };
        mu.enable = true;
        mbsync = {
          enable = true;
          expunge = "both";
          patterns = [ "INBOX" ];
          extraConfig = {
            account = {
              AuthMechs = "XOAUTH2";
            };
          };
        };
      };

    # wayland.windowManager.sway.config = {
    #   output = {
    #     "Applied Creative Technology Transmitter QUATTRO201811" = {
    #       bg = "${self}/files/wallpaper/navidrome.png ${config.stylix.imageScalingMode}";
    #     };
    #     "Hewlett Packard HP Z24i CN44250RDT" = {
    #       bg = "${self}/files/wallpaper/op6wp.png ${config.stylix.imageScalingMode}";
    #     };
    #     "HP Inc. HP 732pk CNC4080YL5" = {
    #       bg = "${self}/files/wallpaper/botanicswp.png ${config.stylix.imageScalingMode}";
    #     };
    #   };
    # };

    wayland.windowManager.sway =
      let
        inherit (confLib.getConfig.repo.secrets.local.work) user1 user1Long domain1 mailAddress;
      in
      {
        config = {
          keybindings =
            let
              inherit (config.wayland.windowManager.sway.config) modifier;
            in
            {
              "${modifier}+Shift+d" = "exec ${pkgs.quickpass}/bin/quickpass work/adm/${user1}/${user1Long}@${domain1}";
              "${modifier}+Shift+i" = "exec ${pkgs.quickpass}/bin/quickpass work/${mailAddress}";
            };
        };
      };

    stylix = {
      targets.firefox.profileNames =
        let
          inherit (confLib.getConfig.repo.secrets.local.work) user1 user2 user3;
        in
        [
          "${user1}"
          "${user2}"
          "${user3}"
          "work"
        ];
    };

    programs =
      let
        inherit (confLib.getConfig.repo.secrets.local.work) user1 user1Long user2 user2Long user3 user3Long user4 path1 loc1 loc2 site1 site2 site3 site4 site5 site6 site7 lifecycle1 lifecycle2 domain1 domain2 gitMail clouds;
      in
      {
        openstackclient = {
          enable = true;
          inherit clouds;
        };
        awscli = {
          enable = true;
          package = pkgs.stable24_05.awscli2;
          # settings = {
          #   "default" = { };
          #   "profile s3-imagebuilder-prod" = { };
          # };
          # credentials = {
          #   "s3-imagebuilder-prod" = {
          #     aws_access_key_id = "5OYXY4879EJG9I91K1B6";
          #     credential_process = "${pkgs.pass}/bin/pass show work/awscli/s3-imagebuilder-prod/secret-key";
          #   };
          # };
        };
        git.settings.user.email = lib.mkForce gitMail;

        zsh = {
          shellAliases = {
            dssh = "ssh -l ${user1Long}";
            cssh = "ssh -l ${user2Long}";
            wssh = "ssh -l ${user3Long}";
          };
          cdpath = [
            "~/Documents/Work"
          ];
          dirHashes = {
            d = "$HOME/.dotfiles";
            w = "$HOME/Documents/Work";
            s = "$HOME/.dotfiles/secrets";
            pr = "$HOME/Documents/Private";
            ac = path1;
          };

          sessionVariables = {
            VSPHERE_USER = "$(cat ${confLib.getConfig.sops.secrets.vcuser.path})";
            VSPHERE_PW = "$(cat ${confLib.getConfig.sops.secrets.vcpw.path})";
            GOVC_USERNAME = "$(cat ${confLib.getConfig.sops.secrets.govcuser.path})";
            GOVC_PASSWORD = "$(cat ${confLib.getConfig.sops.secrets.govcpw.path})";
            GOVC_URL = "$(cat ${confLib.getConfig.sops.secrets.govcurl.path})";
            GOVC_DATACENTER = "$(cat ${confLib.getConfig.sops.secrets.govcdc.path})";
            GOVC_DATASTORE = "$(cat ${confLib.getConfig.sops.secrets.govcds.path})";
            GOVC_HOST = "$(cat ${confLib.getConfig.sops.secrets.govchost.path})";
            GOVC_RESOURCE_POOL = "$(cat ${confLib.getConfig.sops.secrets.govcpool.path})";
            GOVC_NETWORK = "$(cat ${confLib.getConfig.sops.secrets.govcnetwork.path})";
          };
        };

        ssh = {
          matchBlocks = {
            "${loc1}" = {
              hostname = "${loc1}.${domain2}";
              user = user4;
            };
            "${loc1}.stg" = {
              hostname = "${loc1}.${lifecycle1}.${domain2}";
              user = user4;
            };
            "${loc1}.staging" = {
              hostname = "${loc1}.${lifecycle1}.${domain2}";
              user = user4;
            };
            "${loc1}.dev" = {
              hostname = "${loc1}.${lifecycle2}.${domain2}";
              user = user4;
            };
            "${loc2}" = {
              hostname = "${loc2}.${domain1}";
              user = user1Long;
            };
            "${loc2}.stg" = {
              hostname = "${loc2}.${lifecycle1}.${domain2}";
              user = user1Long;
            };
            "${loc2}.staging" = {
              hostname = "${loc2}.${lifecycle1}.${domain2}";
              user = user1Long;
            };
            "*.${domain1}" = {
              user = user1Long;
            };
          };
        };

        firefox = {
          profiles =
            let
              isDefault = false;
            in
            {
              "${user1}" = lib.recursiveUpdate
                {
                  inherit isDefault;
                  id = 1;
                  settings = {
                    "browser.startup.homepage" = "${site1}|${site2}";
                  };
                }
                vars.firefox;
              "${user2}" = lib.recursiveUpdate
                {
                  inherit isDefault;
                  id = 2;
                  settings = {
                    "browser.startup.homepage" = "${site3}";
                  };
                }
                vars.firefox;
              "${user3}" = lib.recursiveUpdate
                {
                  inherit isDefault;
                  id = 3;
                }
                vars.firefox;
              work = lib.recursiveUpdate
                {
                  inherit isDefault;
                  id = 4;
                  settings = {
                    "browser.startup.homepage" = "${site4}|${site5}|${site6}|${site7}";
                  };
                }
                vars.firefox;
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

    services = {
      kanshi = {
        settings = [
          {
            # seminary room
            output = {
              criteria = "Applied Creative Technology Transmitter QUATTRO201811";
              scale = 1.0;
              mode = "1280x720";
            };
          }
          {
            # work side screen
            output = {
              criteria = "HP Inc. HP 732pk CNC4080YL5";
              scale = 1.0;
              mode = "3840x2160";
              transform = "270";
            };
          }
          # {
          #   # work side screen
          #   output = {
          #     criteria = "Hewlett Packard HP Z24i CN44250RDT";
          #     scale = 1.0;
          #     mode = "1920x1200";
          #     transform = "270";
          #   };
          # }
          {
            # work main screen
            output = {
              criteria = "HP Inc. HP Z32 CN41212T55";
              scale = 1.0;
              mode = "3840x2160";
            };
          }
          {
            profile = {
              name = "lidopen";
              exec = [
                "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55' --image ${self}/files/wallpaper/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/op6wp.png --mode ${config.stylix.imageScalingMode}"
              ];
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "enable";
                  scale = 1.5;
                  position = "2560,0";
                }
                {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.0;
                  mode = "3840x2160";
                  position = "-3440,-1050";
                  transform = "270";
                }
                {
                  criteria = "HP Inc. HP Z32 CN41212T55";
                  scale = 1.0;
                  mode = "3840x2160";
                  position = "-1280,0";
                }
              ];
            };
          }
          {
            profile =
              let
                monitor = "Applied Creative Technology Transmitter QUATTRO201811";
              in
              {
                name = "lidopen";
                exec = [
                  "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                  "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/navidrome.png --mode ${config.stylix.imageScalingMode}"
                  "${pkgs.kanshare}/bin/kanshare ${config.swarselsystems.sharescreen} '${monitor}'"
                ];
                outputs = [
                  {
                    criteria = config.swarselsystems.sharescreen;
                    status = "enable";
                    scale = 1.7;
                    position = "2560,0";
                  }
                  {
                    criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                    scale = 1.0;
                    mode = "1280x720";
                    position = "10000,10000";
                  }
                ];
              };
          }
          {
            profile = {
              name = "lidclosed";
              exec = [
                "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55'  --image ${self}/files/wallpaper/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/op6wp.png --mode ${config.stylix.imageScalingMode}"
              ];
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "disable";
                }
                {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.0;
                  mode = "3840x2160";
                  position = "-3440,-1050";
                  transform = "270";
                }
                {
                  criteria = "HP Inc. HP Z32 CN41212T55";
                  scale = 1.0;
                  mode = "3840x2160";
                  position = "-1280,0";
                }
              ];
            };
          }
          {
            profile =
              let
                monitor = "Applied Creative Technology Transmitter QUATTRO201811";
              in
              {
                name = "lidclosed";
                exec = [
                  "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/navidrome.png --mode ${config.stylix.imageScalingMode}"
                ];
                outputs = [
                  {
                    criteria = config.swarselsystems.sharescreen;
                    status = "disable";
                  }
                  {
                    criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                    scale = 1.0;
                    mode = "1280x720";
                    position = "10000,10000";
                  }
                ];
              };
          }
        ];
      };
    };

    systemd.user.services = {
      pizauth.Service = {
        ExecStartPost = [
          "${pkgs.toybox}/bin/sleep 1"
          "//bin/sh -c '${lib.getExe pkgs.pizauth} restore < ${homeDir}/.pizauth.state'"
        ];
      };

      teams-applet = {
        Unit = {
          Description = "teams applet";
          Requires = [ "tray.target" ];
          After = [
            "graphical-session.target"
            "tray.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.stable.teams-for-linux}/bin/teams-for-linux --disableGpu=true --minimized=true --trayIconEnabled=true";
        };
      };

      onepassword-applet = {
        Unit = {
          Description = "1password applet";
          Requires = [ "tray.target" ];
          After = [
            "graphical-session.target"
            "tray.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs._1password-gui-beta}/bin/1password";
        };
      };

    };

    services.pizauth = {
      enable = true;
      extraConfig = ''
        auth_notify_cmd = "if [[ \"$(notify-send -A \"Open $PIZAUTH_ACCOUNT\" -t 30000 'pizauth authorisation')\" == \"0\" ]]; then open \"$PIZAUTH_URL\"; fi";
        error_notify_cmd = "notify-send -t 90000 \"pizauth error for $PIZAUTH_ACCOUNT\" \"$PIZAUTH_MSG\"";
        token_event_cmd = "pizauth dump > ${homeDir}/.pizauth.state";
      '';
      accounts = {
        work = {
          authUri = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
          tokenUri = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
          clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
          clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";
          scopes = [
            "https://outlook.office365.com/IMAP.AccessAsUser.All"
            "https://outlook.office365.com/SMTP.Send"
            "offline_access"
          ];
          loginHint = "${confLib.getConfig.repo.secrets.local.work.mailAddress}";
        };
      };

    };

    xdg =
      let
        inherit (confLib.getConfig.repo.secrets.local.work) user1 user2 user3;
      in
      {
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
            firefox_work = {
              name = "Firefox (work)";
              genericName = "Firefox work";
              exec = "firefox -p work";
              inherit terminal categories icon;
            };
            "firefox_${user1}" = {
              name = "Firefox (${user1})";
              genericName = "Firefox ${user1}";
              exec = "firefox -p ${user1}";
              inherit terminal categories icon;
            };

            "firefox_${user2}" = {
              name = "Firefox (${user2})";
              genericName = "Firefox ${user2}";
              exec = "firefox -p ${user2}";
              inherit terminal categories icon;
            };

            "firefox_${user3}" = {
              name = "Firefox (${user3})";
              genericName = "Firefox ${user3}";
              exec = "firefox -p ${user3}";
              inherit terminal categories icon;
            };


          };
      };
    swarselsystems = {
      startup = [
        # { command = "nextcloud --background"; }
        # { command = "vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime"; }
        # { command = "element-desktop --hidden  --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
        # { command = "anki"; }
        # { command = "obsidian"; }
        # { command = "nm-applet"; }
        # { command = "feishin"; }
        # { command = "teams-for-linux --disableGpu=true --minimized=true --trayIconEnabled=true"; }
        # { command = "1password"; }
      ];
      monitors = {
        work_back_middle = rec {
          name = "LG Electronics LG Ultra HD 0x000305A6";
          mode = "2560x1440";
          scale = "1";
          position = "5120,0";
          workspace = "1:一";
          # output = "DP-10";
          output = name;
        };
        work_front_left = rec {
          name = "LG Electronics LG Ultra HD 0x0007AB45";
          mode = "3840x2160";
          scale = "1";
          position = "5120,0";
          workspace = "1:一";
          # output = "DP-7";
          output = name;
        };
        work_middle_middle_main = rec {
          name = "HP Inc. HP Z32 CN41212T55";
          mode = "3840x2160";
          scale = "1";
          position = "-1280,0";
          workspace = "1:一";
          # output = "DP-3";
          output = name;
        };
        # work_middle_middle_main = rec {
        #   name = "HP Inc. HP 732pk CNC4080YL5";
        #   mode = "3840x2160";
        #   scale = "1";
        #   position = "-1280,0";
        #   workspace = "11:M";
        #   # output = "DP-8";
        #   output = name;
        # };
        work_middle_middle_side = rec {
          name = "HP Inc. HP 732pk CNC4080YL5";
          mode = "3840x2160";
          transform = "270";
          scale = "1";
          position = "-3440,-1050";
          workspace = "12:S";
          # output = "DP-8";
          output = name;
        };
        work_middle_middle_old = rec {
          name = "Hewlett Packard HP Z24i CN44250RDT";
          mode = "1920x1200";
          transform = "270";
          scale = "1";
          position = "-2480,0";
          workspace = "12:S";
          # output = "DP-9";
          output = name;
        };
        work_seminary = rec {
          name = "Applied Creative Technology Transmitter QUATTRO201811";
          mode = "1280x720";
          scale = "1";
          position = "10000,10000"; # i.e. this screen is inaccessible by moving the mouse
          workspace = "14:T";
          # output = "DP-4";
          output = name;
        };
      };
      inputs = {
        "1133:45081:MX_Master_2S_Keyboard" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
        # "2362:628:PIXA3854:00_093A:0274_Touchpad" = {
        #   dwt = "enabled";
        #   tap = "enabled";
        #   natural_scroll = "enabled";
        #   middle_emulation = "enabled";
        #   drag_lock = "disabled";
        # };
        "1133:50504:Logitech_USB_Receiver" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
        "1133:45944:MX_KEYS_S" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
      };

    };
  } // lib.optionalAttrs (type != "nixos") {
    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic && !config.swarselsystems.isNixos) {
      harica-root-ca = {
        sopsFile = certsSopsFile;
        path = "${homeDir}/.aws/certs/harica-root.pem";
        owner = mainUser;
      };
    };

  };

}
