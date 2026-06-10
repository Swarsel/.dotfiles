{ self, inputs, ... }:
let
  inherit (self) outputs;
  inherit (outputs) lib;
in
{
  flake-file.inputs = {
    nixgl.url = "github:guibou/nixGL";
    nur.url = "github:nix-community/NUR";
    vbc-nix.url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
    zjstatus.url = "github:dj95/zjstatus";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  flake =
    {
      overlays =
        let
          nixpkgs-stable-versions = final: _:
            let
              nixpkgsInputs =
                lib.filterAttrs
                  (name: _v: builtins.match "^nixpkgs-.*" name != null)
                  inputs;

              rename = name: builtins.replaceStrings [ "nixpkgs-" ] [ "" ] name;

              mkPkgs = src:
                import src {
                  inherit (final.stdenv.hostPlatform) system;
                  config.allowUnfree = true;
                };
            in
            builtins.listToAttrs (map
              (name: {
                name = rename name;
                value = mkPkgs nixpkgsInputs.${name};
              })
              (builtins.attrNames nixpkgsInputs));

        in
        rec {
          default = additions;
          additions = final: prev:
            let
              additions = final: _: import "${self}/pkgs/flake" { pkgs = final; inherit self lib; }
                // lib.optionalAttrs (inputs ? swarsel-nix) {
                swarsel-nix = import inputs.swarsel-nix {
                  pkgs = prev;
                };
              }
                // lib.optionalAttrs (inputs ? zjstatus) {
                zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
              };

            in
            (additions final prev)
            // (nixpkgs-stable-versions final prev)
            // ((inputs.niri-flake.overlays.niri or (_: _: { })) final prev)
            // ((inputs.noctalia.overlays.default or (_: _: { })) final prev)
            // ((inputs.vbc-nix.overlays.default or (_: _: { })) final prev)
            // ((inputs.nur.overlays.default or (_: _: { })) final prev)
            // ((inputs.emacs-overlay.overlay or (_: _: { })) final prev)
            // ((inputs.nix-topology.overlays.default or (_: _: { })) final prev)
            // ((inputs.nix-index-database.overlays.nix-index or (_: _: { })) final prev)
            // ((inputs.nixgl.overlay or (_: _: { })) final prev)
            // ((inputs.nix-minecraft.overlay or (_: _: { })) final prev)
            // ((inputs.nixos-extra-modules.overlays.default or (_: _: { })) final prev);


          stables = final: prev:
            let
              mkUsePkgsFrom = pkgsFrom: names:
                builtins.listToAttrs (map
                  (name: {
                    inherit name;
                    value = pkgsFrom.${name};
                  })
                  names);

              from =
                let
                  stablePackages = nixpkgs-stable-versions final prev;
                in
                key:
                  stablePackages.${key} or (throw "Missing nixpkgs input nixpkgs-${key}");

            in
            (mkUsePkgsFrom (from "dev") [
              # "swayosd"
              "firezone-relay"
              "firezone-server-web"
              "firezone-server-api"
              "firezone-server-domain"
              "_1password-gui"
              "_1password-gui-beta"
            ])
            // (mkUsePkgsFrom (from "stable24_05") [
              "awscli2"
            ])
            // (mkUsePkgsFrom (from "stable24_11") [
              "python39"
              "spotify"
              "vieb"
            ])
            // (mkUsePkgsFrom (from "stable25_05") [
              "steam-fhsenv-without-steam"
              "transmission_3"
            ])
            // (mkUsePkgsFrom (from "stable25_11") [
              "azure-cli"
            ])
            // (mkUsePkgsFrom (from "stable") [
              # "anki"
              # "bat-extras.batgrep"
              # "bluez"
              # "chromium"
              # "pipewire"
              "teams-for-linux"
            ]);

          modifications = final: prev:
            let
              modifications = final: prev: {
                # vesktop = prev.vesktop.override {
                #   withSystemVencord = true;
                # };

                lib = prev.lib // {
                  swarselsystems = self.outputs.swarselsystemsLib;
                  hm = self.outputs.homeLib;
                };

                firefox = prev.firefox.override {
                  nativeMessagingHosts = [
                    prev.tridactyl-native
                    prev.browserpass
                    # prev.plasma5Packages.plasma-browser-integration
                  ];
                };

                isync = prev.isync.override {
                  withCyrusSaslXoauth2 = true;
                };

                mgba = final.swarsel-mgba;

                retroarch = prev.retroarch.withCores (cores: with cores; [
                  snes9x # snes
                  nestopia # nes
                  dosbox # dos
                  scummvm # scumm
                  vba-m # gb/a
                  mgba # gb/a
                  melonds # ds
                  dolphin # gc/wii
                ]);

                shikane = prev.shikane.overrideAttrs (old: {
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace src/settings.rs \
                      --replace-fail ".create(true)" "" \
                      --replace-fail ".append(true)" ""
                  '';
                });

              };
            in
            modifications final prev;
        };
    };
}
