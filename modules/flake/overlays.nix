{ self, inputs, ... }:
let
  inherit (self) outputs;
  inherit (outputs) lib;

  stablePins = {
    dev = [
      "firezone-relay"
      "firezone-server-web"
      "firezone-server-api"
      "firezone-server-domain"
      # "_1password-gui"
      # "_1password-gui-beta"
    ];
    stable24_11 = [
      "python39"
      "vieb"
    ];
    stable25_05 = [
      "steam-fhsenv-without-steam"
      "transmission_3"
    ];
    stable = [ ];
  };
in
{
  flake-file.inputs = {
    nixgl = {
      url = "github:guibou/nixGL";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    follow-nix = {
      url = "github:Swarsel/follow-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
        git-hooks-nix.follows = "pre-commit-hooks";
      };
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };
  };

  flake = {
    stablePinsUnstable = lib.genAttrs lib.swarselsystems.linuxSystems (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
        };
        supportedOn =
          name:
          let
            r = builtins.tryEval (pkgs ? ${name} && lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.${name});
          in
          r.success && r.value;
      in
      builtins.mapAttrs (
        _: names: lib.genAttrs (builtins.filter supportedOn names) (name: pkgs.${name})
      ) stablePins
    );
    overlays =
      let
        nixpkgs-stable-versions =
          final: _:
          let
            nixpkgsInputs = lib.filterAttrs (name: _v: builtins.match "^nixpkgs-.*" name != null) inputs;

            rename = name: builtins.replaceStrings [ "nixpkgs-" ] [ "" ] name;

            mkPkgs =
              src:
              import src {
                inherit (final.stdenv.hostPlatform) system;
                config.allowUnfree = true;
              };
          in
          builtins.listToAttrs (
            map (name: {
              name = rename name;
              value = mkPkgs nixpkgsInputs.${name};
            }) (builtins.attrNames nixpkgsInputs)
          );

      in
      rec {
        default = additions;
        additions =
          final: prev:
          let
            additions =
              final: _:
              import "${self}/pkgs/flake" {
                pkgs = final;
                inherit self lib;
              }
              // lib.optionalAttrs (inputs ? swarsel-nix) {
                swarsel-nix = import inputs.swarsel-nix {
                  pkgs = prev;
                };
              }
              // lib.optionalAttrs (inputs ? zjstatus) {
                zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
              }
              // lib.optionalAttrs (inputs ? hunkle) {
                hunkle = inputs.hunkle.packages.${prev.stdenv.hostPlatform.system}.default;
              }
              // lib.optionalAttrs (inputs ? follow-nix) {
                follow-nix = inputs.follow-nix.packages.${prev.stdenv.hostPlatform.system}.default;
              };

          in
          (additions final prev)
          // (nixpkgs-stable-versions final prev)
          // ((inputs.niri-flake.overlays.niri or (_: _: { })) final prev)
          // ((inputs.noctalia.overlays.default or (_: _: { })) final prev)
          // ((inputs.nur.overlays.default or (_: _: { })) final prev)
          // ((inputs.emacs-overlay.overlay or (_: _: { })) final prev)
          // ((inputs.nix-topology.overlays.default or (_: _: { })) final prev)
          // ((inputs.nix-index-database.overlays.nix-index or (_: _: { })) final prev)
          // ((inputs.nixgl.overlay or (_: _: { })) final prev)
          // ((inputs.nix-minecraft.overlay or (_: _: { })) final prev)
          // ((inputs.nixos-extra-modules.overlays.default or (_: _: { })) final prev);

        stables =
          final: prev:
          let
            stablePackages = nixpkgs-stable-versions final prev;
            from = suffix: stablePackages.${suffix} or (throw "Missing nixpkgs input nixpkgs-${suffix}");
          in
          lib.concatMapAttrs (suffix: names: lib.genAttrs names (name: (from suffix).${name})) stablePins;

        modifications =
          final: prev:
          let
            modifications = final: prev: {
              lib = prev.lib // {
                swarselsystems = self.outputs.swarselsystemsLib;
                hm = self.outputs.homeLib;
              };

              firefox = prev.firefox.override {
                nativeMessagingHosts = [
                  prev.tridactyl-native
                  prev.browserpass
                ];
              };

              isync = prev.isync.override {
                withCyrusSaslXoauth2 = true;
              };

              mgba = final.swarsel-mgba;

              retroarch = prev.retroarch.withCores (
                cores: with cores; [
                  snes9x # snes
                  nestopia # nes
                  dosbox # dos
                  scummvm # scumm
                  vba-m # gb/a
                  mgba # gb/a
                  melonds # ds
                  dolphin # gc/wii
                ]
              );

              syncstorage-rs =
                (prev.syncstorage-rs.override {
                  python3 = prev.python313;
                }).overrideAttrs
                  (old: {
                    env = (old.env or { }) // {
                      RUSTFLAGS = (old.env.RUSTFLAGS or "") + " -Aambiguous_glob_imports";
                    };
                  });

              shikane = prev.shikane.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace src/settings.rs \
                    --replace-fail ".create(true)" "" \
                    --replace-fail ".append(true)" ""
                '';
              });

              vesktop = prev.vesktop.override {
                withSystemVencord = true;
              };

            };
          in
          modifications final prev;
      };
  };
}
