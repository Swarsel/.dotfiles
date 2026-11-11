{
  flake.modules.nixos.buildbot =
    {
      self,
      root,
      config,
      lib,
      pkgs,
      confLib,
      globals,
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
      inherit (config.swarselsystems) mainUser;

      buildbotHosts =
        lib.concatMap (arch: lib.attrNames (builtins.readDir (self + "/hosts/nixos/${arch}")))
          [
            "aarch64-linux"
            "x86_64-linux"
          ];

      buildbotHome = config.services.buildbot-master.home;
      flakeDir = "${buildbotHome}/flake";
      updateStatusFile = "${buildbotHome}/.update-status";
      retryFile = "${buildbotHome}/.flake-update-retry";
      githubOwner = "Swarsel";
      githubRepo = "${githubOwner}/.dotfiles";
      githubApi = "https://api.github.com/repos/${githubRepo}/pulls";
      buildCommand = ''nix build "${flakeDir}#nixosConfigurations.$HOST.config.system.build.toplevel" --no-link --keep-going --max-jobs 3 --print-out-paths --accept-flake-config'';
      nixBuilders =
        systems:
        ''--builders "${
          lib.concatMapStrings (
            system: "ssh://eu.nixbuild.net ${system} - 100 1 big-parallel,benchmark;"
          ) systems
        }"'';

      buildAndPushBody = ''
        HOST="$1"
        result=$(${buildCommand} || ${buildCommand} --max-jobs 0 ${
          nixBuilders [
            "x86_64-linux"
            "i686-linux"
          ]
        })
        for attempt in 1 2 3; do
            if xargs attic push ${mainUser} <<< "$result"; then
                exit 0
            fi
            if [ "$attempt" -lt 3 ]; then
                sleep 10
            fi
        done
        echo "attic push of $HOST failed after 3 attempts" >&2
      '';

      syncFlake = pkgs.writeShellApplication {
        name = "buildbot-sync-flake";
        text = ''
          (
              flock -x 9
              if [ -d ${flakeDir}/.git ]; then
                  git -C ${flakeDir} fetch origin
                  git -C ${flakeDir} reset --hard origin/main
              else
                  git clone --branch main https://github.com/${githubRepo}.git ${flakeDir}
              fi
          ) 9> ${buildbotHome}/.flake-update.lock
        '';
      };

      buildAndPush = pkgs.writeShellApplication {
        name = "buildbot-build-and-push";
        text = ''
          ${lib.getExe syncFlake}
          ${buildAndPushBody}
        '';
      };

      prepareUpdateBranch = pkgs.writeShellApplication {
        name = "buildbot-prepare-update-branch";
        text = ''
          ${lib.getExe syncFlake}
          cd ${flakeDir}
          git remote set-url --push origin git@github.com:${githubRepo}.git
          git checkout --detach origin/main
          git clean -fdx
          git checkout -B flake-update
        '';
      };

      shouldRunFlakeUpdate = pkgs.writeShellApplication {
        name = "buildbot-should-run-flake-update";
        text = ''
          if [ "''${BUILDBOT_SCHEDULER:-}" = force ] || [ "$(date +%u)" = 1 ] || [ -f ${retryFile} ]; then
              echo 1
          else
              echo no-changes > ${updateStatusFile}
              echo 0
          fi
        '';
      };

      flakeUpdateScript = pkgs.writeShellApplication {
        name = "buildbot-flake-update";
        text = ''
          cd ${flakeDir}
          touch ${retryFile}
          git config user.name buildbot
          git config user.email buildbot@${globals.domains.main}
          git config gpg.format ssh
          git config user.signingkey ${config.sops.secrets.buildbot-github-key.path}
          git config commit.gpgsign true

          nix flake update --accept-flake-config
          if git diff --quiet flake.lock; then
              rm ${retryFile}
              echo no-changes > ${updateStatusFile}
              exit 0
          fi

          nix develop ${flakeDir}#hooks --accept-flake-config -c true
          git add flake.lock
          git commit -m "flake: update inputs $(date +%Y-%m-%d)"
          git push -u origin flake-update --force
          echo has-changes > ${updateStatusFile}
        '';
      };

      buildFlakeUpdate = pkgs.writeShellApplication {
        name = "buildbot-build-flake-update";
        text = ''
          if grep -qx no-changes ${updateStatusFile}; then
              exit 0
          fi
          ${buildAndPushBody}
        '';
      };

      createPR = pkgs.writeShellApplication {
        name = "buildbot-create-pr";
        text = ''
          if grep -qx no-changes ${updateStatusFile}; then
              exit 0
          fi

          api=(curl -sf -H "Authorization: token $(cat ${config.sops.secrets.buildbot-github-token.path})" -H "Accept: application/vnd.github.v3+json")
          existing=$("''${api[@]}" "${githubApi}?head=${githubOwner}:flake-update&state=open")
          if jq -e 'length == 0' <<< "$existing" > /dev/null; then
              "''${api[@]}" -X POST "${githubApi}" \
                -d '{"title": "flake: update inputs", "body": "Automated flake update. All NixOS configurations build.", "head": "flake-update", "base": "main"}'
          fi
          rm ${retryFile}
        '';
      };

      checkStablePins = pkgs.writeShellApplication {
        excludeShellChecks = [ "SC2016" ];
        name = "buildbot-check-stable-pins";
        text = ''
          ${lib.getExe syncFlake}
          pins=$(nix eval --json ${flakeDir}#stablePinsUnstable --apply 'builtins.mapAttrs (_: builtins.mapAttrs (_: builtins.attrNames))' \
            | jq -r 'to_entries[] | .key as $system | .value | to_entries[] | select(.key | startswith("stable")) | .key as $suffix | .value[] | "\($system) \($suffix) \(.)"') || exit 2

          status=0
          while read -r system suffix pkg; do
              if nix build --no-link --max-jobs 0 ${
                nixBuilders [
                  "x86_64-linux"
                  "i686-linux"
                  "aarch64-linux"
                ]
              } "${flakeDir}#stablePinsUnstable.\"$system\".\"$suffix\".\"$pkg\"" > /dev/null 2>&1; then
                  echo "$pkg (nixpkgs-$suffix, $system) builds on unstable and can be unpinned"
                  status=1
              fi
          done <<< "$pins"
          exit $status
        '';
      };

      checkInsecurePermits = pkgs.writeShellApplication {
        excludeShellChecks = [ "SC2016" ];
        name = "buildbot-check-insecure-permits";
        text = ''
          ${lib.getExe syncFlake}
          cd ${flakeDir}
          names=$(mktemp)
          trap 'rm -f "$names"' EXIT

          targets=$(
              nix eval --json .#nixosConfigurations --apply builtins.attrNames --accept-flake-config \
                | jq -r '.[] | "nixosConfigurations.\(.).config.system.build.toplevel"'
              nix eval --json .#devShells --apply 'builtins.mapAttrs (_: builtins.attrNames)' --accept-flake-config \
                | jq -r 'to_entries[] | select(.key | endswith("-linux")) | .key as $system | .value[] | "devShells.\($system).\(.)"'
          ) || exit 2
          for target in $targets; do
              nix-store -qR "$(nix eval --raw ".#$target.drvPath" --accept-flake-config)" || exit 2
          done | sed 's|^/nix/store/[a-z0-9]*-||; s|\.drv$||' | sort -u > "$names"

          status=0
          permits=(${lib.escapeShellArgs pkgs.config.permittedInsecurePackages})
          for permit in "''${permits[@]}"; do
              if ! grep -qxF "$permit" "$names"; then
                  echo "$permit is no longer needed by any output and can be removed from permittedInsecurePackages"
                  status=1
              fi
          done
          exit $status
        '';
      };

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
                command=['${lib.getExe buildAndPush}', host],
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
            command=['${lib.getExe shouldRunFlakeUpdate}'],
            property='run_flake_update',
            env={
                'BUILDBOT_SCHEDULER': util.Interpolate('%(prop:scheduler:-)s'),
            },
            haltOnFailure=True,
        ))
        flake_update_factory.addStep(steps.ShellCommand(
            name='prepare-update-branch',
            command=['${lib.getExe prepareUpdateBranch}'],
            doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
            haltOnFailure=True,
            timeout=600,
        ))
        flake_update_factory.addStep(steps.ShellCommand(
            name='flake-update',
            command=['${lib.getExe flakeUpdateScript}'],
            doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
            haltOnFailure=True,
            timeout=3600,
        ))
        for host in hosts:
            flake_update_factory.addStep(steps.ShellCommand(
                name=f'build-update-{host}',
                command=['${lib.getExe buildFlakeUpdate}', host],
                doStepIf=lambda step: step.build.getProperty('run_flake_update') == '1',
                haltOnFailure=True,
                timeout=28800,
            ))
        flake_update_factory.addStep(steps.ShellCommand(
            name='create-pr',
            command=['${lib.getExe createPR}'],
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
            command=['${lib.getExe checkStablePins}'],
            decodeRC={0: SUCCESS, 1: WARNINGS},
            timeout=7200,
        ))
        builders.append(util.BuilderConfig(
            name='check-stable-pins',
            workernames=['local-worker'],
            factory=pin_check_factory,
        ))

        insecure_check_factory = util.BuildFactory()
        insecure_check_factory.addStep(steps.ShellCommand(
            name='check-insecure-permits',
            command=['${lib.getExe checkInsecurePermits}'],
            decodeRC={0: SUCCESS, 1: WARNINGS},
            timeout=14400,
        ))
        builders.append(util.BuilderConfig(
            name='check-insecure-permits',
            workernames=['local-worker'],
            factory=insecure_check_factory,
        ))

        all_builder_names = build_builder_names + ['flake-update', 'check-stable-pins', 'check-insecure-permits']

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
            schedulers.Periodic(
                name='weekly-insecure-check',
                builderNames=['check-insecure-permits'],
                periodicBuildTimer=604800,
            ),
            schedulers.ForceScheduler(
                name='force',
                builderNames=all_builder_names,
            ),
        ]

        c['www'] = dict(port=${builtins.toString servicePort})

        c['db'] = dict(db_url='sqlite:///state.sqlite')

        c['title'] = '${config.repo.secrets.common.names.buildbot}'
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
          icon = root "files/topology-images/${serviceName}.png";
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
        sops.secrets =
          lib.genAttrs
            [
              "buildbot-age-key"
              "buildbot-github-key"
              "buildbot-github-token"
            ]
            (_: {
              group = "buildbot";
              mode = "0400";
              owner = "buildbot";
            });
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
        services = {
          buildbot-master = {
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
              gnugrep
              gnused
            ];
            pythonPackages = _p: [
              pkgs.buildbot-worker
            ];
          };
          pii-agent = {
            ageKeyFile = config.sops.secrets.buildbot-age-key.path;
            sshKey = null;
            user = serviceName;
          };
        };
        programs.ssh.extraConfig = lib.mkAfter ''
          Host github.com
              IdentityFile ${config.sops.secrets.buildbot-github-key.path}
              IdentitiesOnly yes
              StrictHostKeyChecking accept-new
        '';
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = buildbotHome;
            group = "buildbot";
            mode = "0750";
            user = "buildbot";
          }
        ];
        nix = {
          gc = {
            options = lib.mkForce "--delete-older-than 2d";
            automatic = true;
            dates = lib.mkForce "20:00";
          };
          settings = {
            max-free = lib.mkForce (40 * 1024 * 1024 * 1024);
            min-free = lib.mkForce (15 * 1024 * 1024 * 1024);
            trusted-users = [ "buildbot" ];
          };
        };
        systemd = {
          services = {
            buildbot-master.serviceConfig = {
              MemoryMax = "20G";
              Restart = "always";
            };
            nix-daemon.serviceConfig = {
              MemoryHigh = "14G";
              MemoryMax = "18G";
            };
          };
          tmpfiles.settings."10-buildbot" =
            lib.genAttrs
              [
                flakeDir
                "${buildbotHome}/master"
              ]
              (_: {
                d = {
                  group = "buildbot";
                  mode = "0750";
                  user = "buildbot";
                };
              });
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
    };
}
