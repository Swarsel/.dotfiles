{
  flake.modules.homeManager.zellij =
    {
      self,
      config,
      pkgs,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "zellij" ];
        programs.zellij = {
          enable = true;
          attachExistingSession = false;
          enableZshIntegration = true;
          exitShellOnExit = true;
          settings = {
            copy_command =
              if pkgs.stdenv.hostPlatform.isLinux then
                "wl-copy"
              else if pkgs.stdenv.hostPlatform.isDarwin then
                "pbcopy"
              else
                "";
            copy_on_select = true;
            default_layout = "swarsel";
            default_shell = "zsh";
            layout_dir = "${config.home.homeDirectory}/.config/zellij/layouts";
            on_force_close = "quit";
            pane_frames = false;
            plugins = {
              compact-bar.path = "compact-bar";
              status-bar.path = "status-bar";
              strider.path = "strider";
              tab-bar.path = "tab-bar";
              # configuration.path = "configuration";
              # filepicker.path = "strider";
              # plugin-manager.path = "plugin-manager";
              # session-manager.path = "session-manager";
              # welcome-screen.path = "session-manager";
            };
            scrollback_lines_to_serialize = config.programs.kitty.settings.scrollback_lines;
            session_serialization = true;
            show_startup_tips = false;
            simplified_ui = false;
            support_kitty_keyboard_protocol = true;
            theme_dir = "${config.home.homeDirectory}/.config/zellij/themes";
            ui.pane_frames = {
              hide_session_name = true;
              rounded_corners = true;
            };
          };
        };
        home.packages = with pkgs; [
          zjstatus
        ];
        xdg.configFile."zellij/layouts/swarsel.kdl".text =
          import "${self}/files/zellij/layouts/swarsel.kdl.nix"
            {
              inherit config pkgs;
            };
      };
    };
}
