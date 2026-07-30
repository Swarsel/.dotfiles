{
  flake.modules.homeManager.starship.config = {
    swarselsystems.enabledHomeModules = [ "starship" ];
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        package.symbol = "󰏗 ";
        add_newline = false;
        aws.symbol = " ";
        buf.symbol = " ";
        c.symbol = " ";
        character = {
          error_symbol = "[λ](bold red)";
          success_symbol = "[λ](bold green)";
        };
        command_timeout = 3000;
        conda.symbol = " ";
        dart.symbol = " ";
        directory = {
          read_only = " 󰌾";
          substitutions = {
            Documents = "󰈙 ";
            Downloads = " ";
            Music = " ";
            Pictures = " ";
          };
        };
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        format = "$shlvl$character";
        fossil_branch.symbol = " ";
        git_branch.symbol = " ";
        git_status = {
          format = "[[($all_status$ahead_behind)](fg:#769ff0 bg:#394260)]($style) ";
          style = "bg:#394260";
        };
        golang.symbol = " ";
        guix_shell.symbol = " ";
        haskell.symbol = " ";
        haxe.symbol = " ";
        hg_branch.symbol = " ";
        hostname.ssh_symbol = " ";
        java.symbol = " ";
        julia.symbol = " ";
        lua.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        meson.symbol = "󰔷 ";
        nim.symbol = "󰆥 ";
        nix_shell = {
          disabled = false;
          format = "[$symbol$name]($style)";
          heuristic = true;
          symbol = " ";
        };
        nodejs.symbol = " ";
        os.symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          RedHatEnterprise = " ";
          Redhat = " ";
          Redox = "󰀘 ";
          SUSE = " ";
          Solus = "󰠳 ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = "󰍲 ";
          openSUSE = " ";
        };
        pijul_channel.symbol = " ";
        python.symbol = " ";
        right_format = "$all";
        rlang.symbol = "󰟔 ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";
        shlvl = {
          disabled = false;
          format = "[$symbol]($style) ";
          repeat = true;
          repeat_offset = 1;
          style = "blue";
          symbol = "↳";
        };

      };
    };
  };
}
