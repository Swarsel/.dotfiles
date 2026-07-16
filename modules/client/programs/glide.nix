{
  flake-file.inputs.glide-nix = {
    inputs = {
      home-manager.follows = "home-manager";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:glide-browser/glide.nix";
  };

  flake.modules.homeManager.glide =
    {
      config,
      lib,
      pkgs,
      vars,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "glide" ];
        programs = {
          glide-browser = {
            config = lib.mkBefore ''
              /// <reference types="./glide.d.ts" />

              glide.o.hint_size = "16px";

              glide.o.hint_label_generator = glide.hints.label_generators.numeric;
              glide.o.keymaps_use_physical_layout = "force";
              glide.o.yank_highlight = "${config.lib.stylix.colors.withHashtag.base09}";
            '';
            enable = true;
            nativeMessagingHosts = lib.optionals config.programs.password-store.enable [ pkgs.browserpass ];
            policies = vars.browserPolicies;
            profiles.default = lib.recursiveUpdate vars.glide {
              id = 0;
              isDefault = true;
              settings = {
                "browser.sessionstore.max_resumed_crashes" = 0;
                "browser.sessionstore.resume_from_crash" = false;
                "browser.startup.homepage" = "https://lobste.rs";
                "browser.startup.page" = 1;
              };
            };
          };
          zsh.sessionVariables = {
            MOZ_DISABLE_RDD_SANDBOX = "1";
          };
        };
        home.activation.sponsorblockSettings = vars.sponsorblockActivation;
      };
    };
}
