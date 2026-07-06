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
              browser
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
              initContent = lib.mkIf config.programs.glide-browser.enable ''
                step() {
                  if [[ "$1" == "ssh" && "$2" == "login" ]] && ! pgrep -x .glide-wrapped >/dev/null 2>&1; then
                    niri msg action spawn -- glide >/dev/null 2>&1 || (setsid glide >/dev/null 2>&1 &)
                    sleep 5
                  fi
                  command step "$@"
                }
              '';
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

            firefox = lib.mkIf (!config.programs.glide-browser.enable) {
              profiles =
                let
                  isDefault = false;
                in
                {
                  "${user1}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 1;
                    settings = {
                      "browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user1};
                    };
                  } vars.firefox;
                  "${user2}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 2;
                    settings = {
                      "browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user2};
                    };
                  } vars.firefox;
                  "${user3}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 3;
                  } vars.firefox;
                };
            };

            glide-browser = lib.mkIf config.programs.glide-browser.enable {
              config = lib.mkAfter ''
                container_rules.push(
                  ${lib.concatStringsSep "\n  " (
                    lib.flatten (
                      lib.mapAttrsToList (
                        container:
                        map (prefix: "{ prefix: ${builtins.toJSON prefix}, container: ${builtins.toJSON container} },")
                      ) browser.containerSites
                    )
                  )}
                );
                add_site_shortcuts(${builtins.toJSON browser.siteShortcuts});
              '';

              profiles =
                let
                  mkProfile = attrs: lib.recursiveUpdate vars.glide ({ isDefault = false; } // attrs);
                in
                {
                  default = {
                    containersForce = true;
                    containers = {
                      "${user1}" = {
                        id = 1;
                        color = "blue";
                        icon = "briefcase";
                      };
                      "${user2}" = {
                        id = 2;
                        color = "orange";
                        icon = "fingerprint";
                      };
                      "${user3}" = {
                        id = 3;
                        color = "green";
                        icon = "circle";
                      };
                      work = {
                        id = 4;
                        color = "purple";
                        icon = "briefcase";
                      };
                    };
                    settings = {
                      "privacy.userContext.enabled" = true;
                      "privacy.userContext.ui.enabled" = true;
                    };
                  };
                  "${user1}" = mkProfile {
                    id = 1;
                    settings."browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user1};
                  };
                  "${user2}" = mkProfile {
                    id = 2;
                    settings."browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user2};
                  };
                  "${user3}" = mkProfile { id = 3; };
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
                browser = if config.programs.glide-browser.enable then "glide" else "firefox";
                browserName = lib.swarselsystems.toCapitalized browser;
                mkBrowserEntry = profile: {
                  name = "${browserName} (${profile})";
                  genericName = "${browserName} ${profile}";
                  exec = "${browser} -p ${profile}";
                  terminal = false;
                  categories = [ "Application" ];
                  icon = browser;
                };
              in
              lib.listToAttrs (
                map (profile: lib.nameValuePair "${browser}_${profile}" (mkBrowserEntry profile)) [
                  user1
                  user2
                  user3
                ]
              );
          };
      };
    };
}
