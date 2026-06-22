let
  nix-version = "2_34";

  mkNixPlugins =
    pkgs: lib:
    pkgs.nix-plugins.overrideAttrs (old: {
      buildInputs = [
        pkgs.nixVersions."nix_${nix-version}"
        pkgs.boost
      ];
      postPatch =
        (old.postPatch or "")
        + lib.optionalString (nix-version == "2_34") ''
          substituteInPlace extra-builtins.cc \
          --replace-fail 'Setting<Path> extraBuiltinsFile{this,' 'Setting<std::string> extraBuiltinsFile{this,' \
          --replace-fail 'settings.nixConfDir + "/extra-builtins.nix",' '"/etc/nix/extra-builtins.nix",' \
          --replace-fail '.fun = prim_exec,' '.impl = prim_exec,' \
          --replace-fail '.fun = prim_importNative,' '.impl = prim_importNative,' \
          --replace-fail '.fun = extraBuiltins,' '.impl = extraBuiltins,' \
          --replace-fail '.fun = cflags,' '.impl = cflags,' \
          --replace-fail 'attrs.alloc("NIX_INCLUDE_DIRS").mkString(NIX_INCLUDE_DIRS);' 'attrs.alloc("NIX_INCLUDE_DIRS").mkString(NIX_INCLUDE_DIRS, state.mem);' \
          --replace-fail 'attrs.alloc("NIX_CFLAGS_OTHER").mkString(NIX_CFLAGS_OTHER);' 'attrs.alloc("NIX_CFLAGS_OTHER").mkString(NIX_CFLAGS_OTHER, state.mem);' \
          --replace-fail 'attrs.alloc("BOOST_INCLUDE_DIR").mkString(BOOST_INCLUDE_DIR);' 'attrs.alloc("BOOST_INCLUDE_DIR").mkString(BOOST_INCLUDE_DIR, state.mem);'
        '';
    });

  mkExtraOptions =
    {
      self,
      pkgs,
      lib,
      minimal,
      config,
    }:
    ''
      plugin-files = ${mkNixPlugins pkgs lib}/lib/nix/plugins
      extra-builtins-file = ${self + /files/nix/extra-builtins.nix}
    ''
    + lib.optionalString (!minimal) ''
      !include ${config.sops.secrets.github-api-token.path}
    '';

  experimentalFeatures = [
    "nix-command"
    "flakes"
    "ca-derivations"
    "cgroups"
    "pipe-operators"
  ];

  commonScalarSettings = {
    connect-timeout = 5;
    fallback = true;
    min-free = 128000000;
    max-free = 1000000000;
    auto-optimise-store = true;
    warn-dirty = false;
    max-jobs = 1;
  };

  mkSubstituter =
    isPublic: globals: mainUser:
    [
      "https://nix-community.cachix.org"
    ]
    ++ (
      if isPublic then
        [ ]
      else
        [
          "https://${globals.services.attic.domain}/${mainUser}"
        ]
    );

  baseOverlays = outputs: [
    outputs.overlays.default
    outputs.overlays.stables
    outputs.overlays.modifications
  ];

  mkAdditionsOverlay =
    {
      self,
      config,
      lib,
      homeConfig,
    }:
    (
      final: prev:
      let
        additions =
          final: _:
          import "${self}/pkgs/config" {
            inherit self config lib;
            pkgs = final;
            inherit homeConfig;
          };
      in
      additions final prev
    );
in
{
  flake.modules = {
    nixos.settings =
      {
        self,
        lib,
        pkgs,
        config,
        outputs,
        inputs,
        minimal,
        globals,
        withHomeManager,
        confLib,
        ...
      }:
      let
        inherit (config.swarselsystems) mainUser;
        inherit (config.repo.secrets.common) atticPublicKey;
        settings =
          if minimal then
            { }
          else
            {
              environment.etc."nixos/configuration.nix".source = pkgs.writeText "configuration.nix" ''
                assert builtins.trace "This location is not used. The config is found in ${config.swarselsystems.flakePath}!" false;
                  { }
              '';

              nix =
                let
                  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
                in
                {
                  settings = commonScalarSettings // {
                    bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
                    bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
                    flake-registry = "";
                    use-cgroups = lib.mkIf config.swarselsystems.isLinux true;
                  };
                  gc = {
                    automatic = true;
                    dates = "weekly";
                    options = "--delete-older-than 10d";
                  };
                  optimise = {
                    automatic = true;
                    dates = "weekly";
                  };
                  channel.enable = false;
                  registry = rec {
                    nixpkgs.flake = inputs.nixpkgs;
                    # swarsel.flake = inputs.swarsel;
                    swarsel.flake = self;
                    n = nixpkgs;
                    s = swarsel;
                  };
                  nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
                };

              services.dbus.implementation = "broker";

              systemd.services.nix-daemon = {
                environment.TMPDIR = "/var/tmp";
              };

            };
      in
      {
        config = lib.recursiveUpdate {
          sops = lib.mkIf (!minimal) {
            secrets = {
              github-api-token = {
                owner = mainUser;
                group = "builder";
                mode = "0440";
              };
              attic-cache-key = {
                owner = mainUser;
              };
            };
            templates = {
              netrc = {
                content = ''
                  machine ${globals.services.attic.domain}
                  password ${config.sops.placeholder.attic-cache-key}
                '';
                owner = mainUser;
                group = "builder";
              };
            };
          };

          nix = {
            package = pkgs.nixVersions."nix_${nix-version}";
            settings = {
              experimental-features = experimentalFeatures;
              substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-public-keys =
                lib.optionals (!config.swarselsystems.isPublic) [
                  atticPublicKey
                ]
                ++ [
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              trusted-users = [
                "@wheel"
                "${config.swarselsystems.mainUser}"
                (lib.mkIf (builtins.elem "ssh-builder" config.swarselsystems.enabledServerModules) "builder")
              ];
              netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
            };
            extraOptions = mkExtraOptions {
              inherit
                self
                pkgs
                lib
                minimal
                config
                ;
            };
          };

          users = {
            persistentIds.builder = confLib.mkIds 965;
            groups.builder = { };
          };

          system.stateVersion = lib.mkDefault "23.05";

          nixpkgs = {
            overlays =
              baseOverlays outputs
              ++ lib.optionals withHomeManager [
                (mkAdditionsOverlay {
                  inherit self config lib;
                  homeConfig = config.home-manager.users.${config.swarselsystems.mainUser} or { };
                })
              ];
            config = lib.mkIf (!config.swarselsystems.isMicroVM) {
              allowUnfree = true;
            };
          };

        } settings;
      };

    homeManager.settings =
      {
        self,
        outputs,
        lib,
        pkgs,
        config,
        globals,
        confLib,
        minimal,
        type,
        ...
      }:
      let
        inherit (config.swarselsystems) mainUser flakePath isLinux;
        isStandaloneLinux = type == "home";
        inherit (confLib.getConfig.repo.secrets.common) atticPublicKey;
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "general" ];

          nix = lib.mkIf isStandaloneLinux {
            package = lib.mkForce pkgs.nixVersions."nix_${nix-version}";
            extraOptions = mkExtraOptions {
              inherit
                self
                pkgs
                lib
                minimal
                config
                ;
            };
            settings = commonScalarSettings // {
              experimental-features = experimentalFeatures;
              substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-public-keys = lib.optionals (!config.swarselsystems.isPublic) [
                atticPublicKey
              ];
              trusted-users = [
                "@wheel"
                "${mainUser}"
                # builder user only relevant on NixOS server hosts
              ];
              netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
              bash-prompt-prefix = lib.mkIf config.swarselsystems.isClient "[33m$SHLVL:\\w [0m";
              bash-prompt = lib.mkIf config.swarselsystems.isClient "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
              use-cgroups = lib.mkIf isLinux true;
            };
          };

          nixpkgs = lib.mkIf isStandaloneLinux {
            overlays = baseOverlays outputs ++ [
              (mkAdditionsOverlay {
                inherit self config lib;
                homeConfig = config;
              })
            ];
            config = {
              allowUnfree = true;
            };
          };

          programs = {
            # home-manager.enable = lib.mkIf isStandaloneLinux true;
            man = {
              enable = true;
              generateCaches = true;
            };
          };

          targets.genericLinux.enable = lib.mkIf isStandaloneLinux true;

          home = {
            username = lib.mkDefault mainUser;
            homeDirectory = lib.mkDefault "/home/${mainUser}";
            stateVersion = lib.mkDefault "23.05";
            keyboard.layout = "us";
            sessionVariables = {
              FLAKE = "/home/${mainUser}/.dotfiles";
            };
            extraOutputsToInstall = [
              "doc"
              "info"
              "devdoc"
            ];
            packages = lib.mkIf isStandaloneLinux [
              (pkgs.symlinkJoin {
                name = "home-manager";
                buildInputs = [ pkgs.makeWrapper ];
                paths = [ pkgs.home-manager ];
                postBuild = ''
                      wrapProgram $out/bin/home-manager \
                  --append-flags '--flake ${flakePath}#$(hostname)'
                '';
              })
            ];
          };
        }
        // lib.optionalAttrs isStandaloneLinux {
          sops = lib.mkIf (!config.swarselsystems.isPublic) {
            secrets = {
              github-api-token = {
                mode = "0440";
              };
              attic-cache-key = { };
            };
            templates = {
              netrc = {
                content = ''
                      machine ${globals.services.attic.domain}
                  password ${config.sops.placeholder.attic-cache-key}
                '';
              };
            };
          };
        };
      };

    darwin.settings =
      { outputs, ... }:
      {
        nix.settings.experimental-features = "nix-command flakes";
        nixpkgs = {
          hostPlatform = "x86_64-darwin";
          overlays = baseOverlays outputs;
          config.allowUnfree = true;
        };
        system.stateVersion = 4;
      };
  };
}
