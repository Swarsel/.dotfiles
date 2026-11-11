{
  flake.modules.homeManager.work-dev =
    {
      config,
      lib,
      pkgs,
      confLib,
      glideProfile,
      osConfig,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir;
      inherit (confLib.getConfig.repo.secrets.work)
        browser
        clouds
        githubOrgs
        path1
        sshConfig
        user1
        user1Long
        user2
        user2Long
        user3
        user3Long
        ;
      containerSites = lib.zipAttrsWith (_: lib.concatLists) [
        confLib.getConfig.repo.secrets.common.browser.containerSites
        browser.containerSites
      ];
    in
    {
      imports = [ osConfig.repo.secrets.work.default ];
      config = {
        swarselsystems.homeSopsSecrets =
          lib.genAttrs [ "ucKey" "yubikey-1" "yubikey-2" "yubikey-3" ] (_: {
            rekey.keyPrefix = confLib.static.sharedSecrets.work;
          })
          // {
            harica-root-ca = {
              path = "${homeDir}/.aws/certs/harica-root.pem";
              rekey.keyPrefix = confLib.static.sharedSecrets.clients;
            };
          };
        programs = {
          awscli = {
            enable = true;
            package = pkgs.awscli2;
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
          git.settings.url = lib.genAttrs' githubOrgs (
            org: lib.nameValuePair "git@github.com:${org}/" { insteadOf = "https://github.com/${org}/"; }
          );
          glide-browser = lib.mkIf config.programs.glide-browser.enable {
            config = lib.mkAfter ''
              for (const [container, prefixes] of Object.entries(${builtins.toJSON containerSites})) {
                container_rules.push(...prefixes.map((prefix) => ({ prefix, container })));
              }
              add_site_shortcuts(${builtins.toJSON browser.siteShortcuts});
            '';

            profiles =
              let
                mkProfile = attrs: lib.recursiveUpdate glideProfile ({ isDefault = false; } // attrs);
              in
              {
                "${user1}" = mkProfile {
                  id = 1;
                  settings."browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user1};
                };
                "${user2}" = mkProfile {
                  id = 2;
                  settings."browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user2};
                };
                "${user3}" = mkProfile { id = 3; };
                default = {
                  containers = {
                    "${user1}" = {
                      color = "blue";
                      icon = "briefcase";
                      id = 1;
                    };
                    "${user2}" = {
                      color = "orange";
                      icon = "fingerprint";
                      id = 2;
                    };
                    "${user3}" = {
                      color = "green";
                      icon = "circle";
                      id = 3;
                    };
                    work = {
                      color = "purple";
                      icon = "briefcase";
                      id = 4;
                    };
                  };
                  containersForce = true;
                  settings = {
                    "privacy.userContext.enabled" = true;
                    "privacy.userContext.ui.enabled" = true;
                  };
                };
              };
          };
          openstackclient = {
            enable = true;
            cloudsSettings = { inherit clouds; };
          };
          ssh.settings = lib.recursiveUpdate sshConfig {
            "*".userKnownHostsFile = lib.mkForce "~/.ssh/known_hosts ~/.ssh/known_hosts_work";
          };
          zsh = {
            cdpath = [
              "~/Documents/Work"
            ];
            dirHashes = {
              ac = path1;
              d = "$HOME/.dotfiles";
              pr = "$HOME/Documents/Private";
              s = "$HOME/.dotfiles/secrets";
              w = "$HOME/Documents/Work";
            };
            initContent = lib.mkMerge [
              (lib.mkIf config.programs.glide-browser.enable ''
                step() {
                  if [[ $1 == ssh && $2 == login ]] && ! pgrep -x .glide-wrapped >/dev/null; then
                    niri msg action spawn -- glide >/dev/null
                    sleep 5
                  fi
                  command step "$@"
                }
              '')
              ''
                _vbc_ansible_env() {
                  local tmpl=ansible-2_$1
                  local flake="git+ssh://git@github.com/vbc-it/vbc-nix?ref=main&dir=templates/$tmpl"
                  if [[ -e $HOME/Documents/Work/vbc-nix/templates/$tmpl/flake.nix ]]; then
                    flake=path:$HOME/Documents/Work/vbc-nix/templates/$tmpl
                  fi

                  mkdir -p $HOME/.local/state/nix/profiles/devshells
                  nix develop --profile $HOME/.local/state/nix/profiles/devshells/vbc-$tmpl "$flake" -c zsh
                }
                a215() { _vbc_ansible_env 15; }
                a220() { _vbc_ansible_env 20; }
              ''
            ];
            sessionVariables =
              lib.mapAttrs (_: secret: "$(cat ${confLib.getConfig.sops.secrets.${secret}.path})")
                {
                  ANSIBLE_GALAXY_SERVER_COMMUNITY_TOKEN = "automationhubtoken";
                  ANSIBLE_GALAXY_SERVER_PUBLISHED_TOKEN = "automationhubtoken";
                  ANSIBLE_GALAXY_SERVER_RH_CERTIFIED_TOKEN = "automationhubtoken";
                  ANSIBLE_GALAXY_SERVER_STAGING_TOKEN = "automationhubtoken";
                  GOVC_DATACENTER = "govcdc";
                  GOVC_DATASTORE = "govcds";
                  GOVC_HOST = "govchost";
                  GOVC_NETWORK = "govcnetwork";
                  GOVC_PASSWORD = "govcpw";
                  GOVC_RESOURCE_POOL = "govcpool";
                  GOVC_URL = "govcurl";
                  GOVC_USERNAME = "govcuser";
                  VSPHERE_PW = "vcpw";
                  VSPHERE_USER = "vcuser";
                };
            shellAliases = {
              cssh = "ssh -l ${user2Long}";
              dssh = "ssh -l ${user1Long}";
              wssh = "ssh -l ${user3Long}";
            };
          };
        };
        home = {
          file = {
            ".glide-browser/native-messaging-hosts/com.1password.1password.json" =
              lib.mkIf config.programs.glide-browser.enable
                {
                  text = builtins.toJSON {
                    allowed_extensions = [
                      "{0a75d802-9aed-41e7-8daa-24c067386e82}"
                      "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}"
                      "{d634138d-c276-4fc8-924b-40a0ea21d284}"
                    ];
                    description = "1Password BrowserSupport";
                    name = "com.1password.1password";
                    path = "/run/wrappers/bin/1Password-BrowserSupport";
                    type = "stdio";
                  };
                };
            ".ssh/known_hosts_work".text = ''
              @cert-authority *.vbc.ac.at ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIIQtwt8vkYw9jc4cF9F2TxdpEv8Wc68ofDjUp8AOf3/bKfTcN1yaTpPlTEtwNo/1EnR2lOlrukYrKtw8jKW0nA=
            '';
          };
          packages = with pkgs; [
            teams-for-linux
            shellcheck
            dig
            docker
            postman
            # rclone
            # libguestfs-with-appliance
            prometheus.cli
            tigervnc
            # openstackclient
            step-cli
            openshift

            rustdesk-vbc

            remmina
            packer
            gnumake
            libisoburn
            govc
            opentofu
            terragrunt
            graphviz
            azure-cli
            gh
          ];
          sessionVariables.AWS_CA_BUNDLE = confLib.getConfig.sops.secrets.harica-root-ca.path;
        };
        xdg = {
          desktopEntries = lib.genAttrs' [ user1 user2 user3 ] (
            profile:
            lib.nameValuePair "glide_${profile}" {
              categories = [ "Application" ];
              exec = "glide -p ${profile}";
              genericName = "Glide ${profile}";
              icon = "glide";
              name = "Glide (${profile})";
              terminal = false;
            }
          );
          mimeApps.defaultApplications."x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
        };
        systemd.user = {
          services = {
            onepassword-applet = confLib.mkTrayApplet {
              description = "1password applet";
              execStart = lib.getExe osConfig.programs._1password-gui.package;
            };
            teams-applet = confLib.mkTrayApplet {
              description = "teams applet";
              execStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --disableGpu=true --minimized=true --trayIconEnabled=true";
            };
          };
          sessionVariables.DOCUMENT_DIR_WORK = "${homeDir}/Documents/Work";
        };
      };
    };
}
