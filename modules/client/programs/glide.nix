{
  flake-file.inputs.glide-nix = {
    url = "github:glide-browser/glide.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  flake.modules.homeManager.glide =
    {
      config,
      pkgs,
      lib,
      vars,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "glide" ];

        programs.glide-browser = {
          enable = true;
          policies = vars.browserPolicies;
          nativeMessagingHosts = lib.optionals config.programs.password-store.enable [ pkgs.browserpass ];
          profiles.default = lib.recursiveUpdate vars.glide {
            id = 0;
            isDefault = true;
            settings = {
              "browser.startup.homepage" = "https://lobste.rs";
              "browser.startup.page" = 1;
              "browser.sessionstore.resume_from_crash" = false;
              "browser.sessionstore.max_resumed_crashes" = 0;
            };
          };
          config = lib.mkBefore ''
            /// <reference types="./glide.d.ts" />

            glide.o.hint_size = "16px";

            glide.o.hint_label_generator = glide.hints.label_generators.numeric;
            glide.o.keymaps_use_physical_layout = "force";
            glide.o.yank_highlight = "${config.lib.stylix.colors.withHashtag.base09}";
          '';
        };

        programs.zsh.sessionVariables = {
          MOZ_DISABLE_RDD_SANDBOX = "1";
        };

        home.activation.sponsorblockSettings = vars.sponsorblockActivation;
      };
    };
}
