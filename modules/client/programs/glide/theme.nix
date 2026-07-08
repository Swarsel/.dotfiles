{
  flake.modules.homeManager.glide =
    { config, lib, ... }:
    let
      palette = lib.getAttrs [
        "base00"
        "base01"
        "base02"
        "base03"
        "base04"
        "base05"
        "base06"
        "base07"
        "base08"
        "base09"
        "base0A"
        "base0B"
        "base0C"
        "base0D"
        "base0E"
        "base0F"
      ] config.lib.stylix.colors.withHashtag;
      paletteCss = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "--${name}: ${value};") palette
      );
    in
    {
      programs.glide-browser.config = ''
        glide.styles.add(css`
          :root {
            ${paletteCss}

            --glide-bg: var(--base00);
            --glide-fg: var(--base05);
            --glide-cmdl-bg: var(--base00);
            --glide-cmdl-fg: var(--base0D);
            --glide-cmdl-font-family: "Fira Code", monospace;
            --glide-cmdl-font-size: 1.5rem;
            --glide-cmdl-line-height: 1.5;
            --glide-cmplt-bg: var(--base00);
            --glide-cmplt-fg: var(--base0D);
            --glide-cmplt-font-family: "Fira Code", monospace;
            --glide-cmplt-font-size: 0.8rem;
            --glide-cmplt-border-top: unset;
            --glide-header-first-bg: var(--base01);
            --glide-header-second-bg: var(--base01);
            --glide-header-third-bg: var(--base01);
            --glide-header-font-weight: 200;
            --glide-header-border-bottom: unset;
            --glide-url-fg: var(--base0B);
            --glide-url-bg: var(--base00);
            --glide-of-bg: #44391F;
            --glide-of-fg: var(--base09);
            --glide-status-bg: var(--base00);
            --glide-status-fg: var(--base05);
            --glide-status-border: 1px solid var(--base03);
            --glide-mode-normal: var(--base03);
            --glide-mode-insert: var(--base0B);
            --glide-mode-visual: var(--base09);
            --glide-mode-hint: var(--base0E);
            --glide-mode-ignore: var(--base01);
            --glide-mode-command: var(--base0D);
            --glide-mode-op-pending: var(--base0A);
            --glide-search-highlight-color: var(--base0A);

            --lwt-accent-color: var(--base01) !important;
            --lwt-accent-color-inactive: var(--base01) !important;
            --lwt-text-color: var(--base05) !important;
            --toolbar-bgcolor: var(--base00) !important;
            --toolbar-color: var(--base05) !important;
            --toolbarbutton-icon-fill: var(--base05) !important;
            --toolbarbutton-hover-background: var(--base01) !important;
            --toolbarbutton-active-background: var(--base03) !important;
            --toolbar-field-background-color: var(--base01) !important;
            --toolbar-field-color: var(--base05) !important;
            --toolbar-field-focus-background-color: var(--base01) !important;
            --toolbar-field-focus-color: var(--base05) !important;
            --toolbar-field-border-color: transparent !important;
            --toolbar-field-focus-border-color: var(--base0D) !important;
            --urlbar-box-bgcolor: var(--base01) !important;
            --urlbar-box-focus-bgcolor: var(--base01) !important;
            --urlbar-box-hover-bgcolor: var(--base03) !important;
            --urlbar-popup-url-color: var(--base0D) !important;
            --urlbarView-highlight-background: var(--base03) !important;
            --arrowpanel-background: var(--base00) !important;
            --arrowpanel-color: var(--base05) !important;
            --arrowpanel-border-color: var(--base03) !important;
            --panel-background: var(--base00) !important;
            --panel-color: var(--base05) !important;
            --menu-background-color: var(--base00) !important;
            --menu-color: var(--base05) !important;
            --menuitem-hover-background-color: var(--base03) !important;
            --button-bgcolor: var(--base01) !important;
            --button-color: var(--base05) !important;
            --button-hover-bgcolor: var(--base03) !important;
            --button-primary-bgcolor: var(--base0C) !important;
            --button-primary-hover-bgcolor: var(--base0D) !important;
            --button-primary-color: var(--base00) !important;
            --focus-outline-color: var(--base0D) !important;
            --tab-selected-bgcolor: var(--base00) !important;
            --tab-selected-textcolor: var(--base0D) !important;
            --tab-hover-background-color: var(--base01) !important;
            --sidebar-background-color: var(--base00) !important;
            --sidebar-text-color: var(--base05) !important;
          }

          #navigator-toolbox {
            background-color: var(--base00) !important;
          }

          #TabsToolbar {
            background-color: var(--base01) !important;
          }

          #PersonalToolbar {
            background-color: var(--base00) !important;
            color: var(--base05) !important;
          }

          #urlbar-background {
            background-color: var(--base01) !important;
          }

          #urlbar-container {
            max-width: 50vw !important;
          }

          findbar {
            background-color: var(--base00) !important;
            color: var(--base05) !important;
          }

          .tabbrowser-tab {
            color: var(--base05) !important;
          }

          .tab-background[selected] {
            background-color: var(--base00) !important;
          }

          .tabbrowser-tab[visuallyselected] {
            color: var(--base0D) !important;
          }

          glide-commandline {
            position: fixed !important;
            top: 25% !important;
            bottom: unset !important;
            left: 10% !important;
            width: 80% !important;
            box-shadow: rgba(0, 0, 0, 0.5) 0px 0px 15px !important;
          }

          glide-commandline .glide-commandline-container {
            box-shadow: none;
          }

          glide-commandline [anonid="glide-commandline-holder"] {
            order: 1;
            border: 2px solid var(--base0C);
          }

          glide-commandline [anonid="glide-commandline-completions"] {
            order: 2;
            font-weight: 200;
          }

          glide-commandline [anonid="glide-colon"] {
            display: none;
          }

          glide-commandline input {
            padding: 1rem;
          }

          glide-commandline [anonid="glide-commandline-completions"] > div > table {
            padding: 1rem;
            padding-top: 0;
            width: 100%;
            table-layout: fixed;
          }

          glide-commandline [anonid="glide-commandline-completions"] tr > td {
            width: 100%;
            max-width: 0;
          }
        `, { id: "theme" });
      '';
    };
}
