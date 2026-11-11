{
  flake.modules.nixos.hardwarecompatibility-yubikey =
    {
      root,
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
        programs = {
          ssh = {
            startAgent = false; # yes we want this to use FIDO2 keys
            # enableAskPassword = true;
            # askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
          };
          yubikey-touch-detector = {
            enable = true;
            libnotify = false;
          };
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
        systemd.user.services.yubikey-touch-alarm = {
          after = [
            "graphical-session.target"
            "yubikey-touch-detector.socket"
          ];
          partOf = [ "graphical-session.target" ];
          requires = [ "yubikey-touch-detector.socket" ];
          serviceConfig = {
            ExecStart = lib.getExe (
              pkgs.writeShellApplication {
                name = "yubikey-touch-alarm";
                runtimeInputs = [
                  config.programs.niri.package
                  pkgs.jq
                  pkgs.pipewire
                  pkgs.socat
                  pkgs.yad
                ];
                text = ''
                  declare -A pending
                  pids=()
                  socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/yubikey-touch-detector.socket" STDOUT | while IFS= read -r -n 5 event; do
                    case $event in
                    *_1)
                      pending[''${event%_1}]=1
                      if [[ ''${#pids[@]} -gt 0 ]]; then
                        continue
                      fi

                      {
                        sleep 2
                        factor=$(niri msg --json focused-output | jq '.logical.width / 800 | round | [., 1] | max | [., 6] | min')
                        exec yad --no-buttons --undecorated --borders=0 --name=yubikey-touch --title YubiKey \
                          --image=${
                            pkgs.runCommand "smaaaash" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
                              mkdir $out
                              for factor in $(seq 6); do
                                magick ${root "files/icons/smaaaash.webp"} -filter point -resize $((factor * 100))% $out/$factor.png
                              done
                            ''
                          }/"$factor".png \
                          --css="window, window * { background: transparent; box-shadow: none; }"
                      } &
                      pids+=("$!")

                      {
                        sleep 5
                        for _ in $(seq 30); do
                          pw-play ${root "files/audio/jetztgehtslos.flac"}
                          sleep 1
                        done
                      } &
                      pids+=("$!")
                      ;;
                    *_0)
                      unset "pending[''${event%_0}]"
                      if [[ ''${#pending[@]} -gt 0 ]]; then
                        continue
                      fi

                      kill "''${pids[@]}" 2>/dev/null || true
                      pids=()
                      ;;
                    esac
                  done
                '';
              }
            );
            Restart = "always";
            RestartSec = 2;
          };
          wantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
