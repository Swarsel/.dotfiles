{ self, den, ... }:
let
  sopsFile = self + /secrets/work/secrets.yaml;
  certsSopsFile = self + /secrets/repo/certs.yaml;

  hostContext = { host }: common host;
  homeContext = { home }: common home;

  common = from: {
    nixos = { lib, pkgs, config, ... }:
      let
        inherit (from) mainUser;
        inherit (config.swarselsystems) homeDir;
        iwd = config.networking.networkmanager.wifi.backend == "iwd";
        owner = mainUser;
      in
      {
        options.swarselsystems = {
          hostName = lib.mkOption {
            type = lib.types.str;
            default = config.node.name;
          };
          fqdn = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
        };
        config = {

          sops =
            let
              secretNames = [
                "vcuser"
                "vcpw"
                "govcuser"
                "govcpw"
                "govcurl"
                "govcdc"
                "govcds"
                "govchost"
                "govcnetwork"
                "govcpool"
                "baseuser"
                "basepw"
              ];
            in
            {
              secrets = builtins.listToAttrs (
                map
                  (name: {
                    inherit name;
                    value = { inherit owner sopsFile; };
                  })
                  secretNames
              );
              templates = {
                "network-manager-work.env".content = ''
                  BASEUSER=${config.sops.placeholder.baseuser}
                  BASEPASS=${config.sops.placeholder.basepw}
                '';
              };
            };

          boot.initrd = {
            systemd.enable = lib.mkForce true; # make sure we are using initrd systemd even when not using Impermanence
            luks = {
              # disable "support" since we use systemd-cryptenroll
              # make sure yubikeys are enrolled using
              # sudo systemd-cryptenroll --fido2-device=auto --fido2-with-user-verification=no --fido2-with-user-presence=true --fido2-with-client-pin=no /dev/nvme0n1p2
              yubikeySupport = false;
              fido2Support = false;
            };
          };

          programs = {

            browserpass.enable = true;
            _1password.enable = true;
            _1password-gui = {
              enable = true;
              package = pkgs._1password-gui-beta;
              polkitPolicyOwners = [ "${mainUser}" ];
            };
          };

          networking = {
            inherit (config.swarselsystems) hostName fqdn;

            networkmanager = {
              wifi.scanRandMacAddress = false;
              ensureProfiles = {
                environmentFiles = [
                  "${config.sops.templates."network-manager-work.env".path}"
                ];
                profiles = {
                  VBC = {
                    "802-1x" = {
                      eap = if (!iwd) then "ttls;" else "peap;";
                      identity = "$BASEUSER";
                      password = "$BASEPASS";
                      phase2-auth = "mschapv2";
                    };
                    connection = {
                      id = "VBC";
                      type = "wifi";
                      autoconnect-priority = "500";
                      uuid = "3988f10e-6451-381f-9330-a12e66f45051";
                      secondaries = "48d09de4-0521-47d7-9bd5-43f97e23ff82"; # vpn uuid
                    };
                    ipv4 = { method = "auto"; };
                    ipv6 = {
                      # addr-gen-mode = "default";
                      addr-gen-mode = "stable-privacy";
                      method = "auto";
                    };
                    proxy = { };
                    wifi = {
                      cloned-mac-address = "permanent";
                      mac-address = "E8:65:38:52:63:FF";
                      mac-address-randomization = "1";
                      mode = "infrastructure";
                      band = "a";
                      ssid = "VBC";
                    };
                    wifi-security = {
                      # auth-alg = "open";
                      key-mgmt = "wpa-eap";
                    };
                  };
                };
              };
            };


            nftables = {
              firewall = {
                zones = {
                  virbr = {
                    interfaces = [ "virbr*" ];
                  };
                };
                rules = {
                  virbr-dns-dhcp = {
                    from = [ "virbr" ];
                    to = [ "local" ];
                    allowedTCPPorts = [ 53 ];
                    allowedUDPPorts = [ 53 67 547 ];
                  };
                  virbr-forward = {
                    from = [ "virbr" ];
                    to = [ "untrusted" ];
                    verdict = "accept";
                  };
                  virbr-forward-return = {
                    from = [ "untrusted" ];
                    to = [ "virbr" ];
                    extraLines = [
                      "ct state { established, related } accept"
                    ];
                  };
                };
              };
              chains.postrouting.libvirt-masq = {
                after = [ "dnat" ];
                rules = [
                  "iifname \"virbr*\" masquerade"
                ];
              };
            };

            search = [
              "vbc.ac.at"
              "clip.vbc.ac.at"
              "imp.univie.ac.at"
            ];
          };

          systemd.services = {
            virtqemud.path = with pkgs; [
              qemu_kvm
              libvirt
            ];

            virtstoraged.path = with pkgs; [
              qemu_kvm
              libvirt
            ];

            virtnetworkd.path = with pkgs; [
              dnsmasq
              iproute2
              nftables
            ];
          };

          virtualisation = {
            docker.enable = lib.mkIf (!config.virtualisation.podman.dockerCompat) true;
            spiceUSBRedirection.enable = true;
            libvirtd = {
              enable = true;
              qemu = {
                package = pkgs.qemu_kvm;
                runAsRoot = true;
                swtpm.enable = true;
                vhostUserPackages = with pkgs; [ virtiofsd ];
              };
            };
          };

          environment.systemPackages = with pkgs; [
            remmina
            python39
            qemu
            packer
            gnumake
            libisoburn
            govc
            terraform
            opentofu
            terragrunt
            graphviz
            azure-cli

            # vm
            virt-manager
            virt-viewer
            virtiofsd
            spice
            spice-gtk
            spice-protocol
            virtio-win
            win-spice

            powershell
            gh
          ];

          services = {
            spice-vdagentd.enable = true;
            openssh = {
              enable = true;
              extraConfig = ''
                                    '';
            };

            syncthing = {
              settings = {
                "winters" = {
                  id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
                };
                "moonside@oracle" = {
                  id = "VPCDZB6-MGVGQZD-Q6DIZW3-IZJRJTO-TCC3QUQ-2BNTL7P-AKE7FBO-N55UNQE";
                };
                folders = {
                  "Documents" = {
                    path = "${homeDir}/Documents";
                    devices = [ "moonside@oracle" ];
                    id = "hgr3d-pfu3w";
                  };
                };
              };
            };

            # udev.extraRules = ''
            #   # lock screen when yubikey removed
            #             ACTION=="remove", ENV{PRODUCT}=="3/1050/407/110", RUN+="${pkgs.systemd}/bin/systemctl suspend"
            # '';

          };

          # cgroups v1 is required for centos7 dockers
          # specialisation = {
          #   cgroup_v1.configuration = {
          #     boot.kernelParams = [
          #       "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
          #       "systemd.unified_cgroup_hierarchy=0"
          #     ];
          #   };
          # };
        };
      };
    homeManager = { self, config, pkgs, lib, vars, ... }:
      let
        source = if (config ? home) then "home" else "host";
        inherit (config.swarselsystems) homeDir;
        inherit (config.repo.secrets.local.mail) allMailAddresses;
        inherit (config.repo.secrets.local.work) mailAddress;

      in
      {
        config = {
          home = {
            packages = with pkgs; [
              teams-for-linux
              shellcheck
              dig
              docker
              postman
              # rclone
              libguestfs-with-appliance
              prometheus.cli
              tigervnc
              # openstackclient
              step-cli

              vscode-fhs
              copilot-cli
              antigravity


              rustdesk-vbc
            ];
            sessionVariables = {
              AWS_CA_BUNDLE = source.sops.secrets.harica-root-ca.path;
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
              inherit (from.repo.secrets.local.work) mailName;
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

          wayland.windowManager.sway =
            let
              inherit (from.repo.secrets.local.work) user1 user1Long domain1 mailAddress;
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
                inherit (from.repo.secrets.local.work) user1 user2 user3;
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
              inherit (from.repo.secrets.local.work) user1 user1Long user2 user2Long user3 user3Long path1 site1 site2 site3 site4 site5 site6 site7 clouds;
            in
            {
              openstackclient = {
                enable = true;
                inherit clouds;
              };
              awscli = {
                enable = true;
                package = pkgs.awscli2;
              };

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
                  VSPHERE_USER = "$(cat ${source.sops.secrets.vcuser.path})";
                  VSPHERE_PW = "$(cat ${source.sops.secrets.vcpw.path})";
                  GOVC_USERNAME = "$(cat ${source.sops.secrets.govcuser.path})";
                  GOVC_PASSWORD = "$(cat ${source.sops.secrets.govcpw.path})";
                  GOVC_URL = "$(cat ${source.sops.secrets.govcurl.path})";
                  GOVC_DATACENTER = "$(cat ${source.sops.secrets.govcdc.path})";
                  GOVC_DATASTORE = "$(cat ${source.sops.secrets.govcds.path})";
                  GOVC_HOST = "$(cat ${source.sops.secrets.govchost.path})";
                  GOVC_RESOURCE_POOL = "$(cat ${source.sops.secrets.govcpool.path})";
                  GOVC_NETWORK = "$(cat ${source.sops.secrets.govcnetwork.path})";
                };
              };

              ssh.matchBlocks = from.repo.secrets.local.work.sshConfig;

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

            shikane = {
              settings =
                let
                  workRight = [
                    "m=HP Z32"
                    "s=CN41212T55"
                    "v=HP Inc."
                  ];
                  workLeft = [
                    "m=HP 732pk"
                    "s=CNC4080YL5"
                    "v=HP Inc."
                  ];
                  exec = [ "notify-send shikane \"Profile $SHIKANE_PROFILE_NAME has been applied\"" ];
                in
                {
                  profile = [

                    {
                      name = "work-internal-on";
                      inherit exec;
                      output = [
                        {
                          match = config.swarselsystems.sharescreen;
                          enable = true;
                          scale = 1.7;
                          position = "2560,0";
                        }
                        {
                          match = workRight;
                          enable = true;
                          scale = 1.0;
                          mode = "3840x2160@60Hz";
                          position = "-1280,0";
                        }
                        {
                          match = workLeft;
                          enable = true;
                          scale = 1.0;
                          transform = "270";
                          mode = "3840x2160@60Hz";
                          position = "-3440,-1050";
                        }
                      ];
                    }
                    {
                      name = "work-internal-off";
                      inherit exec;
                      output = [
                        {
                          match = config.swarselsystems.sharescreen;
                          enable = false;
                          scale = 1.7;
                          position = "2560,0";
                        }
                        {
                          match = workRight;
                          enable = true;
                          scale = 1.0;
                          mode = "3840x2160@60Hz";
                          position = "-1280,0";
                        }
                        {
                          match = workLeft;
                          enable = true;
                          scale = 1.0;
                          transform = "270";
                          mode = "3840x2160@60Hz";
                          position = "-3440,-1050";
                        }
                      ];
                    }


                  ];
                };
            };
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
                      "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55' --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                      "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
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
                        "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
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
                      "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55'  --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                      "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
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
                        "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
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
                Requires = [ "graphical-session.target" ];
                After = [
                  "graphical-session.target"
                  "tray.target"
                ];
                PartOf = [
                  "tray.target"
                ];
              };

              Install = {
                WantedBy = [ "tray.target" ];
              };

              Service = {
                ExecStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --disableGpu=true --minimized=true --trayIconEnabled=true";
              };
            };

            onepassword-applet = {
              Unit = {
                Description = "1password applet";
                Requires = [ "graphical-session.target" ];
                After = [
                  "graphical-session.target"
                  "tray.target"
                ];
                PartOf = [
                  "tray.target"
                ];
              };

              Install = {
                WantedBy = [ "tray.target" ];
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
                loginHint = "${from.repo.secrets.local.work.mailAddress}";
              };
            };

          };

          xdg =
            let
              inherit (from.repo.secrets.local.work) user1 user2 user3;
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
        };
      };
  };
in
{
  den = {
    aspects.work = {
      includes = [
        hostContext
        homeContext
        (den.provides.sops { name = "harica-root-ca"; args = { sopsFile = certsSopsFile; path = "/home/swarsel/.aws/certs/harica-root.pem"; }; })
        (den.provides.sops { name = "yubikey-1"; args = { inherit sopsFile; }; })
        (den.provides.sops { name = "ucKey"; args = { inherit sopsFile; }; })
      ];
    };
  };
}
