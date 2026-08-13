{
  flake.modules = {
    homeManager = {
      yubikey =
        {
          config,
          lib,
          confLib,
          type,
          nixosConfig ? null,
          ...
        }:
        let
          inherit (config.swarselsystems) homeDir;
        in
        {

          config = {
            swarselsystems.enabledHomeModules = [ "yubikey" ];
            pam.yubico.authorizedYubiKeys =
              lib.mkIf ((nixosConfig != null) && !config.swarselsystems.isPublic)
                {
                  ids = [
                    confLib.getConfig.repo.secrets.common.yubikeys.dev1
                    confLib.getConfig.repo.secrets.common.yubikeys.dev2
                    confLib.getConfig.repo.secrets.common.yubikeys.dev3
                  ];
                };
          }
          // lib.optionalAttrs (type != "nixos") {
            sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
              u2f-keys.path = "${homeDir}/.config/Yubico/u2f_keys";
            };
          };
        };

      yubikey-touch-detector =
        { lib, pkgs, ... }:
        let
          yubikey-touch-notifier = pkgs.writeShellApplication {
            name = "yubikey-touch-notifier";
            runtimeInputs = with pkgs; [
              coreutils
              findutils
              gawk
              glib
              gnugrep
              iproute2
              libnotify
              socat
            ];
            text = ''
              declare -A ids

              proc_name() {
                local pid=$1 name=""
                IFS= read -r -d "" name < "/proc/$pid/cmdline" 2>/dev/null || true
                name=''${name##*/}
                if [ -z "$name" ]; then
                  name=$(cat "/proc/$pid/comm" 2>/dev/null) || return 1
                fi
                printf '%s' "$name"
              }

              describe_pid() {
                local pid=$1 name ppid pname
                name=$(proc_name "$pid") || return 0
                case "$name" in yubikey-touch*) return 0 ;; esac
                ppid=$(awk '/^PPid:/ { print $2 }' "/proc/$pid/status" 2>/dev/null) || ppid=0
                pname=""
                if [ "''${ppid:-0}" -gt 1 ]; then
                  pname=$(proc_name "$ppid") || pname=""
                fi
                case "$pname" in
                  "" | systemd | init) echo "$name" ;;
                  *) echo "$name ($pname)" ;;
                esac
              }

              requesters() {
                if [ "$#" -eq 0 ]; then
                  return 0
                fi
                local tests=() target out="" line
                for target in "$@"; do
                  tests+=(-o -lname "$target")
                done
                while IFS= read -r line; do
                  out+="''${out:+, }$line"
                done < <(
                  find /proc/[0-9]*/fd -mindepth 1 \( "''${tests[@]:1}" \) -printf '%h\n' 2>/dev/null \
                    | sort -u \
                    | while IFS= read -r fddir; do
                        fddir=''${fddir#/proc/}
                        describe_pid "''${fddir%/fd}"
                      done \
                    | sort -u
                )
                printf '%s' "$out"
              }

              u2f_targets() {
                local uevent dev
                for uevent in /sys/class/hidraw/hidraw*/device/uevent; do
                  [ -e "$uevent" ] || continue
                  if grep -qi '^HID_NAME=.*yubi' "$uevent"; then
                    dev=''${uevent%/device/uevent}
                    printf '/dev/%s\n' "''${dev##*/}"
                  fi
                done
              }

              gpg_targets() {
                local ino
                while IFS= read -r ino; do
                  printf 'socket:\\[%s\\]\n' "$ino"
                done < <(
                  ss -x 2>/dev/null | awk -v p="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent" \
                    '$NF != "0" { for (i = 1; i < NF; i++) if (index($i, p) == 1) { print $NF; break } }'
                )
              }

              dismiss() {
                local kind=$1
                if [ -n "''${ids[$kind]:-}" ]; then
                  gdbus call --session --dest org.freedesktop.Notifications \
                    --object-path /org/freedesktop/Notifications \
                    --method org.freedesktop.Notifications.CloseNotification \
                    "''${ids[$kind]}" > /dev/null 2>&1 || true
                  unset "ids[$kind]"
                fi
              }

              notify() {
                local kind=$1 label=$2 id procs body
                shift 2
                procs=$(requesters "$@")
                body=$label
                if [ -n "$procs" ]; then
                  body="$label: $procs"
                fi
                dismiss "$kind"
                if id=$(notify-send -p -a YubiKey -u critical "YubiKey is waiting for a touch" "$body" 2>/dev/null); then
                  ids[$kind]=$id
                fi
              }

              socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/yubikey-touch-detector.socket" STDOUT | while true; do
                IFS= read -r -n 5 event || break
                case "$event" in
                  GPG_1)
                    mapfile -t targets < <(gpg_targets)
                    notify GPG GPG "''${targets[@]}"
                    ;;
                  U2F_1)
                    mapfile -t targets < <(u2f_targets)
                    notify U2F FIDO2 "''${targets[@]}"
                    ;;
                  MAC_1)
                    mapfile -t targets < <(u2f_targets)
                    notify MAC HMAC "''${targets[@]}"
                    ;;
                  GPG_0) dismiss GPG ;;
                  U2F_0) dismiss U2F ;;
                  MAC_0) dismiss MAC ;;
                  *) ;;
                esac
              done
            '';
          };
        in
        {
          config = {
            swarselsystems.enabledHomeModules = [ "yubikeytouch" ];
            systemd.user = {
              services = {
                yubikey-touch-detector = {
                  Install = {
                    Also = [ "yubikey-touch-detector.socket" ];
                    WantedBy = [ "default.target" ];
                  };
                  Service = {
                    EnvironmentFile = "-%E/yubikey-touch-detector/service.conf";
                    ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
                  };
                  Unit.Requires = [ "yubikey-touch-detector.socket" ];
                };
                yubikey-touch-notifier = {
                  Install.WantedBy = [ "graphical-session.target" ];
                  Service = {
                    ExecStart = lib.getExe yubikey-touch-notifier;
                    Restart = "always";
                    RestartSec = 2;
                  };
                  Unit = {
                    After = [
                      "graphical-session.target"
                      "yubikey-touch-detector.socket"
                    ];
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "yubikey-touch-detector.socket" ];
                  };
                };
              };
              sockets.yubikey-touch-detector = {
                Install.WantedBy = [ "sockets.target" ];
                Socket = {
                  ListenStream = "%t/yubikey-touch-detector.socket";
                  RemoveOnStop = true;
                };
              };
            };
          };
        };
    };
    nixos.hardwarecompatibility-yubikey =
      {
        config,
        lib,
        pkgs,
        confLib,
        ...
      }:
      let
        inherit (config.swarselsystems) mainUser;
        inherit (config.repo.secrets.common.yubikeys) cfg1 cfg2 cfg3;
      in
      {
        config = {

          users.persistentIds.pcscd = confLib.mkIds 956;
          services = {
            gnome.gcr-ssh-agent.enable = false;
            pcscd.enable = true;
            udev.packages = with pkgs; [
              yubikey-personalization
            ];
            yubikey-agent.enable = false;
          };
          programs.ssh = {
            startAgent = false; # yes we want this to use FIDO2 keys
            # enableAskPassword = true;
            # askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
          };
          environment.systemPackages = with pkgs; [
            kdePackages.ksshaskpass
          ];
          hardware.gpgSmartcards.enable = true;
          security.pam.u2f = {
            enable = true;
            control = "sufficient";
            settings = {
              authfile = pkgs.writeText "u2f-mappings" (
                lib.concatStrings [
                  mainUser
                  cfg1
                  cfg2
                  cfg3
                ]
              );
              cue = true; # prints a message that a touch is requrired
              interactive = false; # displays a prompt BEFORE asking for presence
              origin = "pam://${mainUser}"; # make the keys work on all machines
            };
          };
        };
      };
  };
}
