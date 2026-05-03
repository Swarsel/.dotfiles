{ self, lib, pkgs, config, outputs, inputs, minimal, globals, withHomeManager, confLib, ... }:
let
  inherit (config.swarselsystems) mainUser;
  inherit (config.repo.secrets.common) atticPublicKey;
  settings = if minimal then { } else {
    environment.etc."nixos/configuration.nix".source = pkgs.writeText "configuration.nix" ''
      assert builtins.trace "This location is not used. The config is found in ${config.swarselsystems.flakePath}!" false;
        { }
    '';

    nix =
      let
        flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      in
      {
        settings = {
          connect-timeout = 5;
          bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
          bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
          fallback = true;
          min-free = 128000000;
          max-free = 1000000000;
          flake-registry = "";
          auto-optimise-store = true;
          warn-dirty = false;
          max-jobs = 1;
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
  options.swarselmodules.general = lib.mkEnableOption "general nix settings";
  config = lib.mkIf config.swarselmodules.general
    (lib.recursiveUpdate
      {
        sops = lib.mkIf (!minimal) {
          secrets = {
            github-api-token = { owner = mainUser; group = "builder"; mode = "0440"; };
            attic-cache-key = { owner = mainUser; };
          };
          templates = {
            netrc = {
              content = ''
                machine ${globals.services.attic.domain}
                password ${config.sops.placeholder.attic-cache-key}
              '';
              owner = mainUser;
            };
          };
        };

        nix =
          let
            nix-version = "2_34";
          in
          {
            package = pkgs.nixVersions."nix_${nix-version}";
            settings = {
              experimental-features = [
                "nix-command"
                "flakes"
                "ca-derivations"
                "cgroups"
                "pipe-operators"
              ];
              substituters = [
                "https://${globals.services.attic.domain}/${mainUser}"
              ];
              trusted-substituters = [
                "https://${globals.services.attic.domain}/${mainUser}"
              ];
              trusted-public-keys = [
                atticPublicKey
              ];
              trusted-users = [
                "@wheel"
                "${config.swarselsystems.mainUser}"
                (lib.mkIf config.swarselmodules.server.ssh-builder "builder")
              ];
              netrc-file = lib.mkIf (!minimal) config.sops.templates.netrc.path;
            };
            # extraOptions = ''
            #   plugin-files = ${pkgs.dev.nix-plugins}/lib/nix/plugins
            #   extra-builtins-file = ${self + /nix/extra-builtins.nix}
            # '' + lib.optionalString (!minimal) ''
            #   !include ${config.sops.secrets.github-api-token.path}
            # '';
            # extraOptions = ''
            #   plugin-files = ${pkgs.nix-plugins.overrideAttrs (o: {
            #     buildInputs = [config.nix.package pkgs.boost];
            #     patches = o.patches or [];
            #   })}/lib/nix/plugins
            #   extra-builtins-file = ${self + /nix/extra-builtins.nix}
            # '';

            extraOptions =
              let
                # nix-plugins = pkgs.nix-plugins.override {
                #   nixComponents = pkgs.nixVersions."nixComponents_${nix-version}";
                # };
                nix-plugins = pkgs.nix-plugins.overrideAttrs (old: {
                  buildInputs = [ pkgs.nixVersions."nix_${nix-version}" pkgs.boost ];
                  postPatch = (old.postPatch or "") + lib.optionalString (nix-version == "2_34") ''
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
              in
              ''
                plugin-files = ${nix-plugins}/lib/nix/plugins
                extra-builtins-file = ${self + /nix/extra-builtins.nix}
              '' + lib.optionalString (!minimal) ''
                !include ${config.sops.secrets.github-api-token.path}
              '';
          };

        users = {
          persistentIds.builder = confLib.mkIds 965;
          groups.builder = { };
        };

        system.stateVersion = lib.mkDefault "23.05";

        nixpkgs = {
          overlays = [
            outputs.overlays.default
            outputs.overlays.stables
            outputs.overlays.modifications
            # TEMP
            (_: prev: {
              openldap = prev.openldap.overrideAttrs {
                doCheck = !prev.stdenv.hostPlatform.isi686;
              };
            })
          ] ++ lib.optionals withHomeManager [
            (final: prev:
              let
                additions = final: _: import "${self}/pkgs/config" {
                  inherit self config lib;
                  pkgs = final;
                  homeConfig = config.home-manager.users.${config.swarselsystems.mainUser} or { };
                };
              in
              additions final prev
            )
          ];
          config = lib.mkIf (!config.swarselsystems.isMicroVM) {
            allowUnfree = true;
          };
        };

      }
      settings);
}
