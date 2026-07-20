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
      config,
      lib,
      pkgs,
      minimal,
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
    auto-optimise-store = true;
    connect-timeout = 5;
    fallback = true;
    max-free = 1000000000;
    max-jobs = 1;
    min-free = 128000000;
    warn-dirty = false;
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
    outputs.overlays.pedantix-emacs
    outputs.overlays.stables
    outputs.overlays.modifications
  ];

  mkAdditionsOverlay =
    {
      self,
      homeConfig,
      config,
      lib,
    }:
    (
      final: prev:
      let
        additions =
          final: _:
          import "${self}/pkgs/config" {
            inherit self config lib;
            inherit homeConfig;
            pkgs = final;
          };
      in
      additions final prev
    );
in
{
  flake.modules = {
    darwin.settings =
      { outputs, ... }:
      {
        nix.settings.experimental-features = "nix-command flakes";
        nixpkgs = {
          config.allowUnfree = true;
          hostPlatform = "x86_64-darwin";
          overlays = baseOverlays outputs;
        };
        system.stateVersion = 4;
      };
    homeManager.settings =
      {
        self,
        config,
        lib,
        pkgs,
        confLib,
        globals,
        minimal,
        outputs,
        type,
        ...
      }:
      let
        inherit (config.swarselsystems) flakePath isLinux mainUser;
        isStandaloneLinux = type == "home";
        inherit (confLib.getConfig.repo.secrets.common) atticPublicKey;
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "general" ];
          programs = {
            # home-manager.enable = lib.mkIf isStandaloneLinux true;
            man = {
              enable = true;
              generateCaches = true;
            };
          };
          home = {
            extraOutputsToInstall = [
              "doc"
              "info"
              "devdoc"
            ];
            homeDirectory = lib.mkDefault "/home/${mainUser}";
            keyboard.layout = "us";
            packages = lib.mkIf isStandaloneLinux [
              (pkgs.symlinkJoin {
                buildInputs = [ pkgs.makeWrapper ];
                name = "home-manager";
                paths = [ pkgs.home-manager ];
                postBuild = ''
                      wrapProgram $out/bin/home-manager \
                  --append-flags '--flake ${flakePath}#$(hostname)'
                '';
              })
            ];
            sessionVariables.FLAKE = "/home/${mainUser}/.dotfiles";
            stateVersion = lib.mkDefault "23.05";
            username = lib.mkDefault mainUser;
          };
          nix = lib.mkIf isStandaloneLinux {
            package = lib.mkForce pkgs.nixVersions."nix_${nix-version}";
            extraOptions = mkExtraOptions {
              inherit
                self
                config
                lib
                pkgs
                minimal
                ;
            };
            settings = commonScalarSettings // {
              bash-prompt = lib.mkIf config.swarselsystems.isClient "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
              bash-prompt-prefix = lib.mkIf config.swarselsystems.isClient "[33m$SHLVL:\\w [0m";
              experimental-features = experimentalFeatures;
              netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
              substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-public-keys = lib.optionals (!config.swarselsystems.isPublic) [
                atticPublicKey
              ];
              trusted-substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-users = [
                "@wheel"
                "${mainUser}"
                # builder user only relevant on NixOS server hosts
              ];
              use-cgroups = lib.mkIf isLinux true;
            };
          };
          nixpkgs = lib.mkIf isStandaloneLinux {
            config.allowUnfree = true;
            overlays = baseOverlays outputs ++ [
              (mkAdditionsOverlay {
                inherit self config lib;
                homeConfig = config;
              })
            ];
          };
          targets.genericLinux.enable = lib.mkIf isStandaloneLinux true;
        }
        // lib.optionalAttrs isStandaloneLinux {
          sops = lib.mkIf (!config.swarselsystems.isPublic) {
            secrets = {
              attic-cache-key = { };
              github-api-token.mode = "0440";
            };
            templates.netrc.content = ''
                  machine ${globals.services.attic.domain}
              password ${config.sops.placeholder.attic-cache-key}
            '';
          };
        };
      };
    nixos.settings =
      {
        self,
        inputs,
        config,
        lib,
        pkgs,
        confLib,
        globals,
        minimal,
        outputs,
        withHomeManager,
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
              services.dbus.implementation = "broker";
              environment.etc."nixos/configuration.nix".source = pkgs.writeText "configuration.nix" ''
                assert builtins.trace "This location is not used. The config is found in ${config.swarselsystems.flakePath}!" false;
                  { }
              '';
              nix =
                let
                  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
                in
                {
                  channel.enable = false;
                  gc = {
                    options = "--delete-older-than 10d";
                    automatic = true;
                    dates = "weekly";
                  };
                  nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
                  optimise = {
                    automatic = true;
                    dates = "weekly";
                  };
                  registry = rec {
                    n = nixpkgs;
                    nixpkgs.flake = inputs.nixpkgs;
                    s = swarsel;
                    # swarsel.flake = inputs.swarsel;
                    swarsel.flake = self;
                  };
                  settings = commonScalarSettings // {
                    bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
                    bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
                    flake-registry = "";
                    use-cgroups = lib.mkIf config.swarselsystems.isLinux true;
                  };
                };
              systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

            };
      in
      {
        config = lib.recursiveUpdate {
          sops = lib.mkIf (!minimal) {
            secrets = {
              attic-cache-key.owner = mainUser;
              github-api-token = {
                group = "builder";
                mode = "0440";
                owner = mainUser;
              };
            };
            templates.netrc = {
              content = ''
                machine ${globals.services.attic.domain}
                password ${config.sops.placeholder.attic-cache-key}
              '';
              group = "builder";
              owner = mainUser;
            };
          };
          users = {
            groups.builder = { };
            persistentIds.builder = confLib.mkIds 965;
          };
          nix = {
            package = pkgs.nixVersions."nix_${nix-version}";
            extraOptions = mkExtraOptions {
              inherit
                self
                config
                lib
                pkgs
                minimal
                ;
            };
            settings = {
              experimental-features = experimentalFeatures;
              netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
              substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-public-keys =
                lib.optionals (!config.swarselsystems.isPublic) [
                  atticPublicKey
                ]
                ++ [
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              trusted-substituters = mkSubstituter config.swarselsystems.isPublic globals mainUser;
              trusted-users = [
                "@wheel"
                "${config.swarselsystems.mainUser}"
                (lib.mkIf (builtins.elem "ssh-builder" config.swarselsystems.enabledServerModules) "builder")
              ];
            };
          };
          nixpkgs = {
            config = lib.mkIf (!config.swarselsystems.isMicroVM) {
              allowUnfree = true;
            };
            overlays =
              baseOverlays outputs
              ++ lib.optionals withHomeManager [
                (mkAdditionsOverlay {
                  inherit self config lib;
                  homeConfig = config.home-manager.users.${config.swarselsystems.mainUser} or { };
                })
              ];
          };
          system.stateVersion = lib.mkDefault "23.05";

        } settings;
      };
  };
}
