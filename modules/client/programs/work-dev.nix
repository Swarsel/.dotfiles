{
  flake.modules.homeManager.work-dev =
    {
      self,
      inputs,
      config,
      lib,
      pkgs,
      confLib,
      osConfig,
      vars,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir;
      certsSopsFile = self + /secrets/repo/certs.yaml;
      workSopsFile = self + /secrets/work/secrets.yaml;
    in
    {
      imports = lib.optionals (inputs.vbc-nix ? homeManagerModules) [
        osConfig.repo.secrets.work.default
      ];
      config = {
        swarselsystems.homeSopsSecrets = {
          harica-root-ca = {
            path = "${homeDir}/.aws/certs/harica-root.pem";
            sopsFile = certsSopsFile;
          };
          ucKey.sopsFile = workSopsFile;
          yubikey-1.sopsFile = workSopsFile;
          yubikey-2.sopsFile = workSopsFile;
          yubikey-3.sopsFile = workSopsFile;
        };
        programs =
          let
            inherit (confLib.getConfig.repo.secrets.work)
              browser
              clouds
              githubOrgs
              path1
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
            firefox = lib.mkIf (!config.programs.glide-browser.enable) {
              profiles =
                let
                  isDefault = false;
                in
                {
                  "${user1}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 1;
                    settings."browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user1};
                  } vars.firefox;
                  "${user2}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 2;
                    settings."browser.startup.homepage" = lib.concatStringsSep "|" browser.startPages.${user2};
                  } vars.firefox;
                  "${user3}" = lib.recursiveUpdate {
                    inherit isDefault;
                    id = 3;
                  } vars.firefox;
                };
            };
            git.settings.url = lib.listToAttrs (
              map (
                org: lib.nameValuePair "git@github.com:${org}/" { insteadOf = "https://github.com/${org}/"; }
              ) githubOrgs
            );
            glide-browser = lib.mkIf config.programs.glide-browser.enable {
              config = lib.mkAfter ''
                container_rules.push(
                  ${lib.concatStringsSep "\n  " (
                    lib.flatten (
                      lib.mapAttrsToList (
                        container:
                        map (prefix: "{ prefix: ${builtins.toJSON prefix}, container: ${builtins.toJSON container} },")
                      ) containerSites
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
            ssh.settings = lib.recursiveUpdate confLib.getConfig.repo.secrets.work.sshConfig {
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
                    if [[ "$1" == "ssh" && "$2" == "login" ]] && ! pgrep -x .glide-wrapped >/dev/null 2>&1; then
                      niri msg action spawn -- glide >/dev/null 2>&1 || (setsid glide >/dev/null 2>&1 &)
                      sleep 5
                    fi
                    command step "$@"
                  }
                '')
                ''
                  # vbc-nix ansible devshells: local checkout when present, remote otherwise
                  _vbc_ansible_env() {
                    local tmpl="ansible-2_$1"
                    local local_flake="$HOME/Documents/Work/vbc-nix/templates/$tmpl"
                    # --profile registers the dev env as a GC root so nix-collect-garbage keeps it
                    local profile_dir="$HOME/.local/state/nix/profiles/devshells"
                    mkdir -p "$profile_dir"
                    if [[ -e "$local_flake/flake.nix" ]]; then
                      nix develop --profile "$profile_dir/vbc-$tmpl" "path:$local_flake" -c zsh
                    else
                      nix develop --profile "$profile_dir/vbc-$tmpl" "git+ssh://git@github.com/vbc-it/vbc-nix?ref=main&dir=templates/$tmpl" -c zsh
                    fi
                  }
                  a215() { _vbc_ansible_env 15; }
                  a220() { _vbc_ansible_env 20; }
                ''
              ];
              sessionVariables = {
                ANSIBLE_GALAXY_SERVER_COMMUNITY_TOKEN = "$(cat ${confLib.getConfig.sops.secrets.automationhubtoken.path})";
                ANSIBLE_GALAXY_SERVER_PUBLISHED_TOKEN = "$(cat ${confLib.getConfig.sops.secrets.automationhubtoken.path})";
                ANSIBLE_GALAXY_SERVER_RH_CERTIFIED_TOKEN = "$(cat ${confLib.getConfig.sops.secrets.automationhubtoken.path})";
                ANSIBLE_GALAXY_SERVER_STAGING_TOKEN = "$(cat ${confLib.getConfig.sops.secrets.automationhubtoken.path})";
                GOVC_DATACENTER = "$(cat ${confLib.getConfig.sops.secrets.govcdc.path})";
                GOVC_DATASTORE = "$(cat ${confLib.getConfig.sops.secrets.govcds.path})";
                GOVC_HOST = "$(cat ${confLib.getConfig.sops.secrets.govchost.path})";
                GOVC_NETWORK = "$(cat ${confLib.getConfig.sops.secrets.govcnetwork.path})";
                GOVC_PASSWORD = "$(cat ${confLib.getConfig.sops.secrets.govcpw.path})";
                GOVC_RESOURCE_POOL = "$(cat ${confLib.getConfig.sops.secrets.govcpool.path})";
                GOVC_URL = "$(cat ${confLib.getConfig.sops.secrets.govcurl.path})";
                GOVC_USERNAME = "$(cat ${confLib.getConfig.sops.secrets.govcuser.path})";
                VSPHERE_PW = "$(cat ${confLib.getConfig.sops.secrets.vcpw.path})";
                VSPHERE_USER = "$(cat ${confLib.getConfig.sops.secrets.vcuser.path})";
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
          ];
          sessionVariables.AWS_CA_BUNDLE = confLib.getConfig.sops.secrets.harica-root-ca.path;
        };
        xdg =
          let
            inherit (confLib.getConfig.repo.secrets.work) user1 user2 user3;
          in
          {
            desktopEntries =
              let
                browser = if config.programs.glide-browser.enable then "glide" else "firefox";
                browserName = lib.swarselsystems.toCapitalized browser;
                mkBrowserEntry = profile: {
                  categories = [ "Application" ];
                  exec = "${browser} -p ${profile}";
                  genericName = "${browserName} ${profile}";
                  icon = browser;
                  name = "${browserName} (${profile})";
                  terminal = false;
                };
              in
              lib.listToAttrs (
                map (profile: lib.nameValuePair "${browser}_${profile}" (mkBrowserEntry profile)) [
                  user1
                  user2
                  user3
                ]
              );
            mimeApps.defaultApplications."x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
          };
        systemd.user = {
          services = {
            onepassword-applet = {
              Install.WantedBy = [ "tray.target" ];
              Service.ExecStart = "${pkgs._1password-gui-beta}/bin/1password";
              Unit = {
                After = [
                  "graphical-session.target"
                  "tray.target"
                ];
                Description = "1password applet";
                PartOf = [
                  "tray.target"
                ];
                Requires = [ "graphical-session.target" ];
              };
            };
            teams-applet = {
              Install.WantedBy = [ "tray.target" ];
              Service.ExecStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --disableGpu=true --minimized=true --trayIconEnabled=true";
              Unit = {
                After = [
                  "graphical-session.target"
                  "tray.target"
                ];
                Description = "teams applet";
                PartOf = [
                  "tray.target"
                ];
                Requires = [ "graphical-session.target" ];
              };
            };
          };
          sessionVariables.DOCUMENT_DIR_WORK = lib.mkForce "${homeDir}/Documents/Work";
        };
      };
    };
}
