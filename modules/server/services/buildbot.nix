{
  flake.modules.nixos.buildbot =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "buildbot";
          port = 8010;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;
      inherit (config.swarselsystems) mainUser sopsFile;

      nixosHostsForArch =
        arch:
        let
          dir = self + "/hosts/nixos/${arch}";
        in
        if builtins.pathExists dir then builtins.attrNames (builtins.readDir dir) else [ ];

      allNixosHosts = nixosHostsForArch "aarch64-linux" ++ nixosHostsForArch "x86_64-linux";

      excludedHosts = [ ];
      buildbotHosts = builtins.filter (h: !builtins.elem h excludedHosts) allNixosHosts;

      buildbotHome = config.services.buildbot-master.home;
      flakeDir = "${buildbotHome}/flake";
      flakeRepo = "https://github.com/Swarsel/.dotfiles.git";
      flakeRepoSSH = "git@github.com:Swarsel/.dotfiles.git";
      lockFile = "${buildbotHome}/.flake-update.lock";
      updateStatusFile = "${buildbotHome}/.update-status";
      retryFile = "${buildbotHome}/.flake-update-retry";
      githubKeyPath = config.sops.secrets.buildbot-github-key.path;
      githubTokenPath = config.sops.secrets.buildbot-github-token.path;
      buildCommand = ''nix build "${flakeDir}#nixosConfigurations.$HOST.config.system.build.toplevel" --no-link --keep-going --max-jobs 3 --print-out-paths --accept-flake-config'';
      nixBuilders =
        systems:
        ''--builders "''
        + lib.foldl (
          acc: system: acc + "ssh://eu.nixbuild.net ${system} - 100 1 big-parallel,benchmark;"
        ) "" systems
        + ''"'';

      buildAndPushBody = ''
        HOST="$1"
        echo "=== Building nixosConfiguration: $HOST ==="
        result=$(${buildCommand} || ${buildCommand} --max-jobs 0 ${
          nixBuilders [
            "x86_64-linux"
            "i686-linux"
          ]
        })
        echo "Build output: $result"

        attempt=1
        max_attempts=3
        upload_success=0
        while [ $attempt -le $max_attempts ]; do
          echo "=== Pushing $HOST to binary cache (attempt $attempt/$max_attempts) ==="
          if echo "$result" | xargs attic push ${mainUser}; then
            upload_success=1
            break
          fi
          echo "Upload attempt $attempt for $HOST failed."
          attempt=$((attempt + 1))
          if [ $attempt -le $max_attempts ]; then
            sleep 10
          fi
        done

        if [ $upload_success -eq 1 ]; then
          echo "=== Successfully built and pushed $HOST ==="
        else
          echo "=== Build of $HOST succeeded but upload failed after $max_attempts attempts (continuing) ==="
        fi
      '';

      syncFlake = pkgs.writeShellScript "buildbot-sync-flake" ''
        set -euo pipefail
        echo "=== Syncing flake repository ==="
        (
          flock -x 9
          if [ -d "${flakeDir}/.git" ]; then
            cd ${flakeDir}
            git fetch origin
            git reset --hard origin/main
          else
            git clone --branch main ${flakeRepo} ${flakeDir}
          fi
        ) 9>"${lockFile}"
      '';

      buildAndPush = pkgs.writeShellScript "buildbot-build-and-push" ''
        set -euo pipefail
        ${syncFlake}
        ${buildAndPushBody}
      '';

      prepareUpdateBranch = pkgs.writeShellScript "buildbot-prepare-update-branch" ''
        set -euo pipefail
        ${syncFlake}
        cd ${flakeDir}

        git remote set-url --push origin ${flakeRepoSSH}
        git checkout --detach origin/main
        git reset --hard origin/main
        git clean -fdx
        if git show-ref --verify --quiet refs/heads/flake-update; then
          git branch -D flake-update
        fi
        git checkout -b flake-update
      '';

      shouldRunFlakeUpdate = pkgs.writeShellScript "buildbot-should-run-flake-update" ''
        set -euo pipefail
        SCHEDULER="''${BUILDBOT_SCHEDULER:-}"
        if [ "$SCHEDULER" = "force" ] || [ "$(date +%u)" = "1" ] || [ -f ${retryFile} ]; then
          echo "1"
        else
          echo "Not Monday and no retry pending, skipping flake update run." >&2
          echo "no-changes" > ${updateStatusFile}
          echo "0"
        fi
      '';

      flakeUpdateScript = pkgs.writeShellScript "buildbot-flake-update" ''
        set -euo pipefail
        cd ${flakeDir}

        touch ${retryFile}

        git config user.name "buildbot"
        git config user.email "buildbot@swarsel.win"
        git config gpg.format ssh
        git config user.signingkey "${githubKeyPath}"
        git config commit.gpgsign true
        nix flake update --accept-flake-config
        if git diff --quiet flake.lock; then
          echo "No flake.lock changes, nothing to do."
          rm -f ${retryFile}
          echo "no-changes" > ${updateStatusFile}
          exit 0
        fi
        echo "=== Realizing dev environment for git hooks ==="
        nix develop ${flakeDir}#hooks --accept-flake-config -c true
        git add flake.lock
        git commit -m "flake: update inputs $(date +%Y-%m-%d)"
        git push -u origin flake-update --force
        echo "has-changes" > ${updateStatusFile}
      '';

      buildFlakeUpdate = pkgs.writeShellScript "buildbot-build-flake-update" ''
        set -euo pipefail
        if [ "$(cat ${updateStatusFile} 2>/dev/null)" = "no-changes" ]; then
          echo "No changes, skipping build."
          exit 0
        fi
        ${buildAndPushBody}
      '';

      createPR = pkgs.writeShellScript "buildbot-create-pr" ''
        set -euo pipefail
        if [ "$(cat ${updateStatusFile} 2>/dev/null)" = "no-changes" ]; then
          echo "No changes, skipping PR creation."
          exit 0
        fi
        TOKEN=$(cat ${githubTokenPath})

        existing=$(curl -s \
          -H "Authorization: token $TOKEN" \
          -H "Accept: application/vnd.github.v3+json" \
          "https://api.github.com/repos/Swarsel/.dotfiles/pulls?head=Swarsel:flake-update&state=open")

        if echo "$existing" | jq -e 'length > 0' > /dev/null 2>&1; then
          echo "PR already exists, force-push updated it."
          rm -f ${retryFile}
          exit 0
        fi

        curl -f -X POST \
          -H "Authorization: token $TOKEN" \
          -H "Accept: application/vnd.github.v3+json" \
          "https://api.github.com/repos/Swarsel/.dotfiles/pulls" \
          -d '{"title": "flake: update inputs", "body": "Automated flake update. All NixOS configurations built successfully.", "head": "flake-update", "base": "main"}'

        rm -f ${retryFile}
      '';

      pinEnumApply = ''
        attrs:
          let
            stableSuffixes = builtins.filter (s: builtins.substring 0 6 s == "stable");
            forSystem = system: suffixes: builtins.concatLists (map
              (suffix: map
                (name: system + " " + suffix + " " + name)
                (builtins.attrNames suffixes.''${suffix}))
              (stableSuffixes (builtins.attrNames suffixes)));
          in
          builtins.concatStringsSep "\n"
            (builtins.concatLists (builtins.attrValues (builtins.mapAttrs forSystem attrs)))
      '';

      checkStablePins = pkgs.writeShellScript "buildbot-check-stable-pins" ''
        set -uo pipefail
        ${syncFlake}
        candidates=()
        keep=()
        check() {
          if nix build --no-link --max-jobs 0 ${
            nixBuilders [
              "x86_64-linux"
              "i686-linux"
              "aarch64-linux"
            ]
          } \
               "${flakeDir}#stablePinsUnstable.\"$1\".\"$2\".\"$3\"" \
               > /dev/null 2>&1; then
            candidates+=("$3 (nixpkgs-$2, $1)")
          else
            keep+=("$3 (nixpkgs-$2, $1)")
          fi
        }
        pinlist=$(nix eval --raw "${flakeDir}#stablePinsUnstable" --apply ${lib.escapeShellArg pinEnumApply}) || {
          echo "ERROR: failed to enumerate stable pins from the flake" >&2
          exit 2
        }
        while read -r system suffix pkg; do
          [ -n "$system" ] && check "$system" "$suffix" "$pkg"
        done <<< "$pinlist"
        echo "=== Stable-pin check: tried building each pinned package from current unstable nixpkgs (per supported platform) ==="
        echo "fork-pinned packages (nixpkgs-dev) are excluded; review those manually."
        echo ""
        if [ ''${#keep[@]} -eq 0 ] && [ ''${#candidates[@]} -eq 0 ]; then
          echo "No stable pins with a checkable unstable target."
          exit 0
        fi
        if [ ''${#keep[@]} -gt 0 ]; then
          echo "Still broken on unstable, keep pinned:"
          printf '  - %s\n' "''${keep[@]}"
          echo ""
        fi
        if [ ''${#candidates[@]} -gt 0 ]; then
          echo "Now build on unstable, can likely be un-pinned (remove from stablePins in modules/flake/overlays.nix):"
          printf '  - %s\n' "''${candidates[@]}"
          exit 1
        fi
        echo "No un-pin candidates; all checked pins are still needed."
      '';

      masterCfg = pkgs.writeText "master.cfg" ''
        from buildbot.plugins import *
        from buildbot.process.results import SUCCESS, WARNINGS

        c = BuildmasterConfig = {}

        c['workers'] = [worker.LocalWorker('local-worker', max_builds=1)]
        c['protocols'] = {'pb': {'port': 9989}}

        hosts = ${builtins.toJSON buildbotHosts}

        builders = []
        build_builder_names = []

        for host in hosts:
            f = util.BuildFactory()
            f.addStep(steps.ShellCommand(
                name='build-and-push',
                command=['${buildAndPush}', host],
                timeout=28800,
            ))
            builders.append(util.BuilderConfig(
                name=f'build-{host}',
                workernames=['local-worker'],
                factory=f,
            ))
            build_builder_names.append(f'build-{host}')

        flake_update_factory = util.BuildFactory()
        flake_update_factory.addStep(steps.SetPropertyFromCommand(
          name='should-run-flake-update',
          command=['${shouldRunFlakeUpdate}'],
          property='run_flake_update',
          env={
            'BUILDBOT_SCHEDULER': util.Interpolate('%(prop:scheduler:-)s'),
          },
          haltOnFailure=True,
        ))
        flake_update_factory.addStep(steps.ShellCommand(
            name='prepare-update-branch',
            command=['${prepareUpdateBranch}'],
            doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
            haltOnFailure=True,
            timeout=600,
        ))
        flake_update_factory.addStep(steps.ShellCommand(
            name='flake-update',
            command=['${flakeUpdateScript}'],
          doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
            haltOnFailure=True,
            timeout=3600,
        ))
        for host in hosts:
            flake_update_factory.addStep(steps.ShellCommand(
                name=f'build-update-{host}',
                command=['${buildFlakeUpdate}', host],
                doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
                haltOnFailure=True,
                timeout=28800,
            ))
        flake_update_factory.addStep(steps.ShellCommand(
            name='create-pr',
            command=['${createPR}'],
            doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
            timeout=300,
        ))
        builders.append(util.BuilderConfig(
            name='flake-update',
            workernames=['local-worker'],
            factory=flake_update_factory,
        ))

        pin_check_factory = util.BuildFactory()
        pin_check_factory.addStep(steps.ShellCommand(
            name='check-stable-pins',
            command=['${checkStablePins}'],
            decodeRC={0: SUCCESS, 1: WARNINGS},
            timeout=7200,
        ))
        builders.append(util.BuilderConfig(
            name='check-stable-pins',
            workernames=['local-worker'],
            factory=pin_check_factory,
        ))

        all_builder_names = build_builder_names + ['flake-update', 'check-stable-pins']

        c['builders'] = builders

        c['schedulers'] = [
            schedulers.Periodic(
                name='nightly',
                builderNames=build_builder_names,
                periodicBuildTimer=86400,
            ),
            schedulers.Nightly(
              name='daily-flake-update',
                builderNames=['flake-update'],
                hour=3,
                minute=0,
            ),
            schedulers.Periodic(
                name='weekly-pin-check',
                builderNames=['check-stable-pins'],
                periodicBuildTimer=604800,
            ),
            schedulers.ForceScheduler(
                name='force',
                builderNames=all_builder_names,
            ),
        ]

        c['www'] = dict(port=${builtins.toString servicePort})

        c['db'] = dict(db_url='sqlite:///state.sqlite')

        c['title'] = 'SwarselSystems CI'
        c['titleURL'] = 'https://${serviceDomain}'
        c['buildbotURL'] = 'https://${serviceDomain}/'
        c['buildbotNetUsageData'] = None
      '';
    in
    {
      imports = [
        self.modules.nixos.attic-setup
      ];
      config = {
        swarselsystems.enabledServerModules = [ "buildbot" ];
        topology.self.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = "Buildbot";
        };
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "Buildbot Web UI";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets = {
          buildbot-age-key = {
            inherit sopsFile;
            group = "buildbot";
            mode = "0400";
            owner = "buildbot";
          };
          buildbot-github-key = {
            inherit sopsFile;
            group = "buildbot";
            mode = "0400";
            owner = "buildbot";
          };
          buildbot-github-token = {
            inherit sopsFile;
            group = "buildbot";
            mode = "0400";
            owner = "buildbot";
          };
        };
        users = {
          users.${serviceName} = {
            extraGroups = [ "builder" ];
            subGidRanges = [
              {
                count = 999;
                startGid = 1001;
              }
            ];
            subUidRanges = [
              {
                count = 65534;
                startUid = 100001;
              }
            ];
          };
          persistentIds.${serviceName} = confLib.mkIds 1002; # must be a normal user
        };
        services.buildbot-master = {
          inherit masterCfg;
          enable = true;
          home = "/home/buildbot";
          packages = with pkgs; [
            config.nix.package
            bash
            coreutils
            ssh-to-age
            git
            attic-client
            util-linux
            openssh
            sops
            curl
            jq
          ];
          pythonPackages = _p: [
            pkgs.buildbot-worker
          ];
        };
        programs.ssh.extraConfig = lib.mkAfter ''
          Host github.com
              IdentityFile ${config.sops.secrets.buildbot-github-key.path}
              IdentitiesOnly yes
              StrictHostKeyChecking accept-new
        '';
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = "/home/buildbot";
            group = "buildbot";
            mode = "0750";
            user = "buildbot";
          }
        ];
        nix = {
          gc = {
            options = lib.mkForce "--delete-older-than 5d";
            automatic = true;
            dates = lib.mkForce "20:00";
          };
          settings.trusted-users = [ "buildbot" ];
        };
        systemd = {
          services.buildbot-master = {
            environment.SOPS_AGE_KEY_FILE = config.sops.secrets.buildbot-age-key.path;
            serviceConfig = {
              MemoryMax = "20G";
              Restart = "always";
            };
          };
          tmpfiles.settings."10-buildbot" = builtins.listToAttrs (
            map
              (path: {
                name = "/home/buildbot/${path}";
                value = {
                  d = {
                    group = "buildbot";
                    mode = "0750";
                    user = "buildbot";
                  };
                };
              })
              [
                "/flake"
                "/master"
              ]
          );
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              oauth2 = true;
              oauth2Groups = [ "buildbot_access" ];
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                oauth2Groups = [ "buildbot_access" ];
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
