{
  flake.modules.homeManager.work-dev =
    {
      self,
      inputs,
      config,
      pkgs,
      lib,
      vars,
      confLib,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir;
      certsSopsFile = self + /secrets/repo/certs.yaml;
      workSopsFile = self + /secrets/work/secrets.yaml;
    in
    {
      imports = lib.optionals (inputs.vbc-nix ? homeManagerModules) [
        inputs.vbc-nix.homeManagerModules.ontap-mcp
        inputs.vbc-nix.homeManagerModules.claude
        {
          swarselsystems.homeSopsSecrets = {
            ontap-mcp-config.sopsFile = "${inputs.vbc-nix}/secrets/mcp.yaml";
            claude-mcp-env.sopsFile = "${inputs.vbc-nix}/secrets/mcp.yaml";
            vcenter-config = {
              sopsFile = "${inputs.vbc-nix}/secrets/mcp.yaml";
              path = "${homeDir}/.config/vcenter-mcp/config.json";
            };
            openshift-kubeconfig = {
              sopsFile = "${inputs.vbc-nix}/secrets/mcp.yaml";
              path = "${homeDir}/.config/openshift-mcp/kubeconfig";
            };
          };
          services.ontap-mcp = {
            enable = true;
            configFile = confLib.getConfig.sops.secrets."ontap-mcp-config".path;
          };
          programs.claude = {
            enable = true;
            mcp = {
              enable = true;
              envFile = confLib.getConfig.sops.secrets."claude-mcp-env".path;
            };
          };
        }
      ];

      config = {
        swarselsystems.homeSopsSecrets = {
          harica-root-ca = {
            sopsFile = certsSopsFile;
            path = "${homeDir}/.aws/certs/harica-root.pem";
          };
          yubikey-1 = {
            sopsFile = workSopsFile;
          };
          yubikey-2 = {
            sopsFile = workSopsFile;
          };
          yubikey-3 = {
            sopsFile = workSopsFile;
          };
          ucKey = {
            sopsFile = workSopsFile;
          };
        };

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
            openshift

            ontap-mcp
            rustdesk-vbc
          ];
          sessionVariables = {
            AWS_CA_BUNDLE = confLib.getConfig.sops.secrets.harica-root-ca.path;
          };
          file.".ssh/known_hosts_work".text = ''
            @cert-authority *.vbc.ac.at ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIIQtwt8vkYw9jc4cF9F2TxdpEv8Wc68ofDjUp8AOf3/bKfTcN1yaTpPlTEtwNo/1EnR2lOlrukYrKtw8jKW0nA=
          '';
        };
        systemd.user.sessionVariables = {
          DOCUMENT_DIR_WORK = lib.mkForce "${homeDir}/Documents/Work";
        };

        programs =
          let
            inherit (confLib.getConfig.repo.secrets.local.work)
              user1
              user1Long
              user2
              user2Long
              user3
              user3Long
              path1
              site1
              site2
              site3
              site4
              site5
              site6
              site7
              clouds
              ;
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

            ssh.settings = lib.recursiveUpdate confLib.getConfig.repo.secrets.local.work.sshConfig {
              "*".userKnownHostsFile = lib.mkForce "~/.ssh/known_hosts ~/.ssh/known_hosts_work";
            };

            firefox = {
              profiles =
                let
                  isDefault = false;
                in
                {
                  "${user1}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 1;
                    settings = {
                      "browser.startup.homepage" = "${site1}|${site2}";
                    };
                  } vars.firefox;
                  "${user2}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 2;
                    settings = {
                      "browser.startup.homepage" = "${site3}";
                    };
                  } vars.firefox;
                  "${user3}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 3;
                  } vars.firefox;
                  work = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 4;
                    settings = {
                      "browser.startup.homepage" = "${site4}|${site5}|${site6}|${site7}";
                    };
                  } vars.firefox;
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

        systemd.user.services = {
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
      };
    };
}
