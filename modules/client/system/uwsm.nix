{
  flake.modules.nixos.uwsm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.uwsm;
    in
    {
      config = {
        services.displayManager.sessionPackages =
          let
            mk_uwsm_desktop_entry =
              opts:
              (pkgs.writeTextFile {
                derivationArgs = {
                  passthru.providedSessions = [ "${opts.name}-uwsm" ];
                };
                destination = "/share/wayland-sessions/${opts.name}-uwsm.desktop";
                name = "${opts.name}-uwsm";
                text = ''
                  [Desktop Entry]
                  Name=${opts.prettyName} (UWSM)
                  Comment=${opts.comment}
                  Exec=${lib.getExe cfg.package} start -F -- ${opts.binPath} ${lib.strings.escapeShellArgs opts.extraArgs}
                  Type=Application
                '';
              });
          in
          lib.mkForce (
            lib.mapAttrsToList (
              name: value:
              mk_uwsm_desktop_entry {
                inherit name;
                inherit (value)
                  binPath
                  comment
                  extraArgs
                  prettyName
                  ;
              }
            ) cfg.waylandCompositors
          );
        programs.uwsm = {
          enable = true;
          waylandCompositors = {
            niri = lib.mkIf (config.programs ? niri) {
              binPath = "/run/current-system/sw/bin/niri-session";
              comment = "Niri compositor managed by UWSM";
              prettyName = "Niri";
            };
            sway = {
              binPath = "/run/current-system/sw/bin/sway";
              comment = "Sway compositor managed by UWSM";
              prettyName = "Sway";
            };
          };
        };
      };
    };
}
