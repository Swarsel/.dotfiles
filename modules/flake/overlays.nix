{
  self,
  root,
  inputs,
  ...
}:
let
  inherit (self) outputs;
  inherit (outputs) lib;

  stablePins = {
    dev = [ ];
    firezone = [
      "firezone-gateway"
      "firezone-headless-client"
      "firezone-relay"
      "firezone-server"
    ];
    stable = [
      "dwarfs"
      "wayprompt"
    ];
    stable25_05 = [
      "steam-fhsenv-without-steam"
      "transmission_3"
    ];
    stable26_05 = [
      "azure-cli"
      "libdisplay-info_0_2"
    ];
  };
in
{
  flake-file.inputs = {
    emacs-overlay = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
      url = "github:nix-community/emacs-overlay";
    };

    follow-nix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/follow-nix";
    };

    nix-minecraft = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
      url = "github:Infinidoge/nix-minecraft";
    };

    nixgl = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:guibou/nixGL";
    };

    nur = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:nix-community/NUR";
    };

    zjstatus = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:dj95/zjstatus";
    };
  };

  flake = {
    overlays =
      let
        nixpkgs-stable-versions =
          final: _:
          lib.mapAttrs' (
            name: src:
            lib.nameValuePair (lib.removePrefix "nixpkgs-" name) (
              import src {
                inherit (final.stdenv.hostPlatform) system;
                config.allowUnfree = true;
              }
            )
          ) (lib.filterAttrs (name: _: lib.hasPrefix "nixpkgs-" name) inputs);
      in
      rec {
        additions =
          final: prev:
          let
            inherit (prev.stdenv.hostPlatform) system;
          in
          import "${self}/pkgs/flake" {
            inherit self lib;
            pkgs = final;
          }
          // {
            follow-nix = inputs.follow-nix.packages.${system}.default;
            hunkle = inputs.hunkle.packages.${system}.default;
            pedantix = inputs.pedantix.packages.${system}.pedantix-wrapped;
            swarsel-nix = import inputs.swarsel-nix { pkgs = prev; };
            zjstatus = inputs.zjstatus.packages.${system}.default;
          }
          // nixpkgs-stable-versions final prev
          // lib.mergeAttrsList (
            map (overlay: overlay final prev) [
              inputs.niri-flake.overlays.niri
              inputs.noctalia.overlays.default
              inputs.nur.overlays.default
              inputs.emacs-overlay.overlay
              inputs.nix-topology.overlays.default
              inputs.nix-index-database.overlays.nix-index
              inputs.nixgl.overlay
              inputs.nix-minecraft.overlay
              inputs.nixos-extra-modules.overlays.default
            ]
          );

        default = additions;

        modifications = _final: prev: {
          firezone-gui-client = prev.firezone-gui-client.overrideAttrs (
            old:
            let
              frontend = old.passthru.frontend.overrideAttrs {
                patches = [ (root "files/patches/firezone-gui-client-update-state-loop.patch") ];
              };
            in
            {
              passthru = old.passthru // {
                inherit frontend;
              };
              postPatch = builtins.replaceStrings [ "${old.passthru.frontend}" ] [ "${frontend}" ] old.postPatch;
            }
          );
          go-mockery = prev.go-mockery.overrideAttrs { doCheck = false; };
          grafanaPlugins = prev.grafanaPlugins // {
            grafana-pyroscope-datasource = prev.grafanaPlugins.grafanaPlugin {
              packages.any = {
                hash = "sha256-JZHurlO+5Anr5VDcO9sXewxjLIPkz6JAchkF9qkLR4Y=";
                url = "https://grafana.com/api/plugins/grafana-pyroscope-datasource/versions/13.0.9/download";
              };
              pname = "grafana-pyroscope-datasource";
              version = "13.0.9";
            };
          };
          isync = prev.isync.override {
            withCyrusSaslXoauth2 = true;
          };
          lib = prev.lib // {
            inherit (self.outputs.lib) hm;
            swarselsystems = self.outputs.swarselsystemsLib;
          };
          matrix-appservice-irc = prev.matrix-appservice-irc.overrideAttrs {
            patches = [
              (root "files/patches/matrix-appservice-irc-on-connect-commands.patch")
              (root "files/patches/matrix-appservice-irc-pm-room-v12.patch")
              (root "files/patches/matrix-appservice-irc-provisioner-silent-pm.patch")
            ];
          };
          mautrix-signal = prev.mautrix-signal.overrideAttrs {
            patches = [ (root "files/patches/mautrix-signal-upload-length.patch") ];
          };
          mautrix-telegram = prev.mautrix-telegram.override {
            python3 = prev.python313;
          };
          niri-unstable = prev.niri-unstable.override {
            patches = [
              (root "files/patches/niri-workspace-under-mouse-binds.patch")
              (root "files/patches/niri-hidden-workspaces.patch")
              (root "files/patches/niri-hidden-workspaces-event-stream.patch")
            ];
          };
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
          sesh = prev.sesh.overrideAttrs {
            doCheck = false;
            preBuild = "";
          };
          shikane = prev.shikane.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/settings.rs \
                  --replace-fail ".create(true)" "" \
                  --replace-fail ".append(true)" ""
            '';
          });
          syncstorage-rs =
            (prev.syncstorage-rs.override {
              python3 = prev.python313;
            }).overrideAttrs
              (old: {
                env = old.env // {
                  RUSTFLAGS = (old.env.RUSTFLAGS or "") + " -Aambiguous_glob_imports";
                };
              });
          vencord = prev.vencord.overrideAttrs (old: {
            patches = [ ];
            pnpmDeps = old.pnpmDeps.overrideAttrs {
              outputHash = "sha256-/BoLLeKsftWv1bjWuND8967YGhqWEaCZZU6z/oa+0oM=";
              patches = [ ];
              postPatch = "";
            };
            postPatch = "";
            src = old.src.override {
              hash = "sha256-+dN4wAFNmYVDiEe0QStqrFBRFHBBRkApqbmhuvsLZZM=";
              tag = "v1.15.17";
            };
            version = "1.15.17";
          });
          vesktop = prev.vesktop.override {
            withSystemVencord = true;
          };
          zellij-unwrapped = prev.zellij-unwrapped.overrideAttrs (old: {
            postPatch =
              old.postPatch
              +
                lib.concatMapStrings
                  (name: ''
                    substituteInPlace zellij-utils/src/input/layout.rs \
                          --replace-fail 'available_layouts.push(LayoutInfo::BuiltIn("${name}".to_owned()));' ""
                  '')
                  [
                    "default"
                    "strider"
                    "disable-status-bar"
                    "compact"
                    "classic"
                  ];
          });
        };

        pedantix-emacs = inputs.pedantix.overlays.emacs;

        stables =
          final: prev:
          let
            stablePackages = nixpkgs-stable-versions final prev;
          in
          lib.concatMapAttrs (
            suffix: names: lib.genAttrs names (name: stablePackages.${suffix}.${name})
          ) stablePins;
      };
    stablePinsUnstable = lib.genAttrs lib.swarselsystems.linuxSystems (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config = {
            allowBroken = true;
            allowUnfree = true;
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
  };
}
