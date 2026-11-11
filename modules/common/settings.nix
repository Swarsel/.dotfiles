let
  nix-version = "2_34";

  mkExtraOptions =
    config: minimal: if minimal then "" else "!include ${config.sops.secrets.github-api-token.path}\n";

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

  mkCaches =
    {
      atticPublicKey,
      globals,
      isPublic,
      mainUser,
    }:
    {
      substituters = [
        "https://nix-community.cachix.org"
      ]
      ++ (if isPublic then [ ] else [ "https://${globals.services.attic.domain}/${mainUser}" ]);
      trusted-public-keys = (if isPublic then [ ] else [ atticPublicKey ]) ++ [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

  mkCacheSecrets = confLib: globals: config: {
    secrets = {
      attic-cache-key.rekey.keyPrefix = confLib.static.sharedSecrets.common;
      github-api-token = {
        mode = "0440";
        rekey.keyPrefix = confLib.static.sharedSecrets.common;
      };
    };
    templates.netrc.content = ''
      machine ${globals.services.attic.domain}
      password ${config.sops.placeholder.attic-cache-key}
    '';
  };

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
    final: _:
    import "${self}/pkgs/config" {
      inherit
        self
        homeConfig
        config
        lib
        ;
      pkgs = final;
    };
in
{
  flake.modules = {
    darwin.settings =
      { config, outputs, ... }:
      {
        nix.settings.experimental-features = "nix-command flakes";
        nixpkgs = {
          config.allowUnfree = true;
          hostPlatform = config.node.arch;
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
        inherit (config.swarselsystems)
          flakePath
          homeDir
          isLinux
          isPublic
          mainUser
          ;
        isStandaloneLinux = type == "home";
        caches = mkCaches {
          inherit (confLib.getConfig.repo.secrets.common) atticPublicKey;
          inherit globals isPublic mainUser;
        };
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "general" ];
          programs.man = {
            enable = true;
            generateCaches = true;
          };
          home = {
            extraOutputsToInstall = [
              "doc"
              "info"
              "devdoc"
            ];
            homeDirectory = lib.mkDefault homeDir;
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
            sessionVariables.FLAKE = flakePath;
            stateVersion = lib.mkDefault "23.05";
            username = lib.mkDefault mainUser;
          };
          nix = lib.mkIf isStandaloneLinux {
            package = lib.mkForce pkgs.nixVersions."nix_${nix-version}";
            extraOptions = mkExtraOptions config minimal;
            settings = commonScalarSettings // {
              bash-prompt = lib.mkIf config.swarselsystems.isClient "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
              bash-prompt-prefix = lib.mkIf config.swarselsystems.isClient "[33m$SHLVL:\\w [0m";
              experimental-features = experimentalFeatures;
              extra-substituters = caches.substituters;
              extra-trusted-public-keys = caches.trusted-public-keys;
              extra-trusted-substituters = caches.substituters;
              netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
              trusted-users = [
                "@wheel"
                mainUser
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
          sops = lib.mkIf (!isPublic) (mkCacheSecrets confLib globals config);
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
        inherit (config.swarselsystems) isPublic mainUser;
        caches = mkCaches {
          inherit (config.repo.secrets.common) atticPublicKey;
          inherit globals isPublic mainUser;
        };
        secretsOwner = lib.mkIf config.users.users.${mainUser}.enable mainUser;
      in
      {
        config = lib.mkMerge [
          {
            sops = lib.mkIf (!minimal) (
              lib.mkMerge [
                (mkCacheSecrets confLib globals config)
                {
                  secrets = {
                    attic-cache-key.owner = secretsOwner;
                    github-api-token = {
                      group = "builder";
                      owner = secretsOwner;
                    };
                  };
                  templates.netrc = {
                    group = "builder";
                    owner = secretsOwner;
                  };
                }
              ]
            );
            users = {
              groups.builder = { };
              persistentIds.builder = confLib.mkIds 965;
            };
            nix = {
              package = pkgs.nixVersions."nix_${nix-version}";
              extraOptions = mkExtraOptions config minimal;
              settings = {
                inherit (caches) substituters trusted-public-keys;
                experimental-features = experimentalFeatures;
                netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
                trusted-substituters = caches.substituters;
                trusted-users = [
                  "@wheel"
                  (lib.mkIf config.users.users.${mainUser}.enable mainUser)
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
                    homeConfig = config.home-manager.users.${mainUser} or { };
                  })
                ];
            };
            system.stateVersion = lib.mkDefault "23.05";
          }
          (lib.mkIf (!minimal) {
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
          })
        ];
      };
  };
}
