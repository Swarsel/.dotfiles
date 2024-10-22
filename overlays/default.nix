{ inputs, ... }: {
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = _: _prev: {
    vesktop = _prev.vesktop.override {
      withSystemVencord = true;
    };

    nerdfonts = _prev.nerdfonts.override {
      fonts = [ "FiraMono" "FiraCode" "NerdFontsSymbolsOnly" ];
    };

    firefox = _prev.firefox.override {
      nativeMessagingHosts = [
        _prev.tridactyl-native
        _prev.browserpass
        _prev.plasma5Packages.plasma-browser-integration
      ];
    };

    # prismlauncher = _prev.prismlauncher.override {
    #   glfw = _prev.glfw-wayland-minecraft;
    # };

    # #river = prev.river.overrideAttrs (oldAttrs: rec {
    #   pname = "river";
    #   version = "git";
    #   src = prev.fetchFromGitHub {
    #     owner = "riverwm";
    #     repo = pname;
    #     rev = "c16628c7f57c51d50f2d10a96c265fb0afaddb02";
    #     hash = "sha256-E3Xtv7JeCmafiNmpuS5VuLgh1TDAbibPtMo6A9Pz6EQ=";
    #     fetchSubmodules = true;
    #   };
    # });
  };

  nixpkgs-stable = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  zjstatus = _: _prev: {
    zjstatus = inputs.zjstatus.packages.${_prev.system}.default;
  };

}
