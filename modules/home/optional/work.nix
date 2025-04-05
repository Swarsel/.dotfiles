{ self, config, pkgs, lib, nix-secrets, ... }:
let
  inherit (config.swarselsystems) homeDir;
  secretsDirectory = builtins.toString nix-secrets;
  dcUser = lib.swarselsystems.getSecret "${secretsDirectory}/work/dc-user";
  clUser = lib.swarselsystems.getSecret "${secretsDirectory}/work/cl-user";
  wsUser = lib.swarselsystems.getSecret "${secretsDirectory}/work/ws-user";
in
{
  options.swarselsystems.modules.optional.work = lib.mkEnableOption "optional work settings";
  config = lib.mkIf config.swarselsystems.modules.optional.work {
    home.packages = with pkgs; [
      stable.teams-for-linux
      shellcheck
      dig
      docker
      postman
      rclone
      stable.awscli2
      libguestfs-with-appliance
      stable.prometheus.cli
      tigervnc
      openstackclient
    ];

    home.sessionVariables = {
      DOCUMENT_DIR_PRIV = lib.mkForce "${homeDir}/Documents/Private";
      DOCUMENT_DIR_WORK = lib.mkForce "${homeDir}/Documents/Work";
    };

    wayland.windowManager.sway.config = {
      output = {
        "Applied Creative Technology Transmitter QUATTRO201811" = {
          bg = "${self}/wallpaper/navidrome.png ${config.stylix.imageScalingMode}";
        };
        "Hewlett Packard HP Z24i CN44250RDT" = {
          bg = "${self}/wallpaper/op6wp.png ${config.stylix.imageScalingMode}";
        };
        "HP Inc. HP 732pk CNC4080YL5" = {
          bg = "${self}/wallpaper/botanicswp.png ${config.stylix.imageScalingMode}";
        };
      };
    };

    stylix.targets.firefox.profileNames = [
      "dc"
      "cl"
      "ws"
    ];

    programs = {
      git.userEmail = lib.swarselsystems.getSecret "${secretsDirectory}/work/git-email";

      zsh = {
        shellAliases = {
          dssh = "ssh -l ${dcUser}";
          cssh = "ssh -l ${clUser}";
          wssh = "ssh -l ${wsUser}";
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
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/uc-prod";
            user = "stack";
          };
          "uc.stg" = {
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/uc-stg";
            user = "stack";
          };
          "uc.staging" = {
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/uc-stg";
            user = "stack";
          };
          "uc.dev" = {
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/uc-dev";
            user = "stack";
          };
          "cbe" = {
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/cbe-prod";
            user = dcUser;
          };
          "cbe.stg" = {
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/cbe-stg";
            user = dcUser;
          };
          "cbe.staging" = {
            hostname = lib.swarselsystems.getSecret "${secretsDirectory}/work/cbe-stg";
            user = dcUser;
          };
          "*.vbc.ac.at" = {
            user = dcUser;
          };
        };
      };

      firefox = {
        profiles =
          let
            isDefault = false;
          in
          {
            dc = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 1;
                settings = {
                  "browser.startup.homepage" = "https://tower.vbc.ac.at|https://artifactory.vbc.ac.at";
                };
              }
              config.swarselsystems.firefox;
            cl = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 2;
                settings = {
                  "browser.startup.homepage" = "https://portal.azure.com";
                };
              }
              config.swarselsystems.firefox;
            ws = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 3;
              }
              config.swarselsystems.firefox;
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
            # work main screen
            output = {
              criteria = "HP Inc. HP 732pk CNC4080YL5";
              scale = 1.0;
              mode = "3840x2160";
            };
          }
          {
            # work side screen
            output = {
              criteria = "Hewlett Packard HP Z24i CN44250RDT";
              scale = 1.0;
              mode = "1920x1200";
              transform = "270";
            };
          }
          {
            profile = {
              name = "lidopen";
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "enable";
                  scale = 1.5;
                  position = "1462,0";
                }
                {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.4;
                  mode = "3840x2160";
                  position = "-1280,0";
                }
                {
                  criteria = "Hewlett Packard HP Z24i CN44250RDT";
                  scale = 1.0;
                  mode = "1920x1200";
                  transform = "90";
                  position = "-2480,0";
                }
              ];
            };
          }
          {
            profile = {
              name = "lidopen";
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
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "disable";
                }
                {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.4;
                  mode = "3840x2160";
                  position = "-1280,0";
                }
                {
                  criteria = "Hewlett Packard HP Z24i CN44250RDT";
                  scale = 1.0;
                  mode = "1920x1200";
                  transform = "270";
                  position = "-2480,0";
                }
              ];
            };
          }
          {
            profile = {
              name = "lidclosed";
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
            name = "Firefox (dc)";
            genericName = "Firefox dc";
            exec = "firefox -p dc";
            inherit terminal categories icon;
          };

          firefox_ws = {
            name = "Firefox (ws)";
            genericName = "Firefox ws";
            exec = "firefox -p ws";
            inherit terminal categories icon;
          };

          firefox_cl = {
            name = "Firefox (cl)";
            genericName = "Firefox cl";
            exec = "firefox -p cl";
            inherit terminal categories icon;
          };

        };
    };
  };

}
