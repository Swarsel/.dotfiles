{ self, inputs, ... }:
let
  inherit (self) outputs;
  inherit (outputs) lib;
in
{
  flake = _:
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
                // {
                swarsel-nix = import inputs.swarsel-nix {
                  pkgs = prev;
                };
                zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
              };

            in
            (additions final prev)
            // (nixpkgs-stable-versions final prev)
            // (inputs.niri-flake.overlays.niri final prev)
            // (inputs.noctalia.overlays.default final prev)
            // (inputs.vbc-nix.overlays.default final prev)
            // (inputs.nur.overlays.default final prev)
            // (inputs.emacs-overlay.overlay final prev)
            // (inputs.nix-topology.overlays.default final prev)
            // (inputs.nix-index-database.overlays.nix-index final prev)
            // (inputs.nixgl.overlay final prev)
            // (inputs.nix-minecraft.overlay final prev)
            // (inputs.nixos-extra-modules.overlays.default final prev);


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
            // (mkUsePkgsFrom (from "stable") [
              # "anki"
              "azure-cli"
              # "bat-extras.batgrep"
              # "bluez"
              "calibre"
              # "chromium"
              "dwarfs"
              "gotenberg"
              "khal"
              "libreoffice"
              "libreoffice-qt"
              "nerd-fonts-symbols-only"
              "noto-fonts-color-emoji"
              # "pipewire"
              "podman"
              "teams-for-linux"
              # "vesktop"
              "virtualbox"
              "inkscape"
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

                noctalia-shell = prev.noctalia-shell.override {
                  calendarSupport = true;
                };

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

              };
            in
            modifications final prev;
        };
    };
}
