{ self, lib, config, pkgs, ... }:
{
  options.swarselmodules.zellij = lib.mkEnableOption "zellij settings";
  config = lib.mkIf config.swarselmodules.zellij {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        pane_frames = false;
        simplified_ui = false;
        default_shell = "zsh";
        copy_on_select = true;
        on_force_close = "detach";
        show_startup_tips = false;
        support_kitty_keyboard_protocol = true;
        default_layout = "swarsel";
        layout_dir = "${config.home.homeDirectory}/.config/zellij/layouts";
        theme_dir = "${config.home.homeDirectory}/.config/zellij/themes";
        scrollback_lines_to_serialize = config.programs.kitty.settings.scrollback_lines;
        session_serialization = true;

        copy_command =
          if pkgs.stdenv.hostPlatform.isLinux then
            "wl-copy"
          else if pkgs.stdenv.hostPlatform.isDarwin then
            "pbcopy"
          else
            "";
        ui.pane_frames = {
          rounded_corners = true;
          hide_session_name = true;
        };
        plugins = {
          tab-bar.path = "tab-bar";
          status-bar.path = "status-bar";
          strider.path = "strider";
          compact-bar.path = "compact-bar";
          # configuration.path = "configuration";
          # filepicker.path = "strider";
          # plugin-manager.path = "plugin-manager";
          # session-manager.path = "session-manager";
          # welcome-screen.path = "session-manager";
        };
      };
    };

    home.packages = with pkgs; [
      zjstatus
    ];

    xdg.configFile = {
      # "zellij/config.kdl".text = import "${self}/files/zellij/config.kdl.nix" { inherit config; };
      "zellij/layouts/swarsel.kdl".text = import "${self}/files/zellij/layouts/swarsel.kdl.nix" { inherit config pkgs; };
    };
  };

}
