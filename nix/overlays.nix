{ self, inputs, ... }:
let
  inherit (self) outputs;
  inherit (outputs) lib;
in
{
  flake = _:
    {
      overlays = {
        default = final: prev:
          let
            additions = final: _: import "${self}/pkgs" { pkgs = final; inherit self lib; }
              // {
              swarsel-nix = import inputs.swarsel-nix {
                pkgs = prev;
              };
              zjstatus = inputs.zjstatus.packages.${prev.system}.default;
            };

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

            };

            nixpkgs-stable-versions = final: _:
              let
                nixpkgsInputs =
                  lib.filterAttrs
                    (name: _v: builtins.match "^nixpkgs-.*" name != null)
                    inputs;

                rename = name: builtins.replaceStrings [ "nixpkgs-" ] [ "" ] name;

                mkPkgs = src:
                  import src {
                    inherit (final) system;
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
          lib.recursiveUpdate
            (
              (additions final prev)
              // (nixpkgs-stable-versions final prev)
              // (inputs.niri-flake.overlays.niri final prev)
              // (inputs.vbc-nix.overlays.default final prev)
              // (inputs.nur.overlays.default final prev)
              // (inputs.emacs-overlay.overlay final prev)
              // (inputs.nix-topology.overlays.default final prev)
              // (inputs.nixgl.overlay final prev)
              // (inputs.nixos-extra-modules.overlays.default final prev)
            )
            (modifications final prev);
      };
    };
}
