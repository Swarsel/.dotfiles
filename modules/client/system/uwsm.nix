{
  flake.modules.nixos.uwsm = { lib, config, pkgs, ... }:
    let
      cfg = config.programs.uwsm;
    in
    {
      config = {
        programs.uwsm = {
          enable = true;
          waylandCompositors = {
            sway = {
              prettyName = "Sway";
              comment = "Sway compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/sway";
            };
            niri = lib.mkIf (config.programs ? niri) {
              prettyName = "Niri";
              comment = "Niri compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/niri-session";
            };
          };
        };

        services.displayManager.sessionPackages =
          let
            mk_uwsm_desktop_entry =
              opts:
              (pkgs.writeTextFile {
                name = "${opts.name}-uwsm";
                text = ''
                  [Desktop Entry]
                  Name=${opts.prettyName} (UWSM)
                  Comment=${opts.comment}
                  Exec=${lib.getExe cfg.package} start -F -- ${opts.binPath} ${lib.strings.escapeShellArgs opts.extraArgs}
                  Type=Application
                '';
                destination = "/share/wayland-sessions/${opts.name}-uwsm.desktop";
                derivationArgs = {
                  passthru.providedSessions = [ "${opts.name}-uwsm" ];
                };
              });
          in
          lib.mkForce (lib.mapAttrsToList
            (
              name: value:
                mk_uwsm_desktop_entry {
                  inherit name;
                  inherit (value)
                    prettyName
                    comment
                    binPath
                    extraArgs
                    ;
                }
            )
            cfg.waylandCompositors);
      };
    };
}
