{ self, lib, config, pkgs, confLib, ... }:
let
  inherit (confLib.gen { name = "buildbot"; port = 8010; }) serviceName servicePort serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) mainUser sopsFile;

  nixosHostsForArch = arch:
    let dir = self + "/hosts/nixos/${arch}";
    in if builtins.pathExists dir then builtins.attrNames (builtins.readDir dir) else [ ];

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
  nixBuilders = systems: ''--builders "'' + lib.foldl (acc: system: acc + ''ssh://eu.nixbuild.net ${system} - 100 1 big-parallel,benchmark;'') "" systems + ''"'';

  buildAndPushBody = ''
    HOST="$1"
    echo "=== Building nixosConfiguration: $HOST ==="
    result=$(${buildCommand} || ${buildCommand} --max-jobs 0 ${nixBuilders [ "x86_64-linux" "i686-linux" ]})
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

  buildAndPush = pkgs.writeShellScript "buildbot-build-and-push" ''
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

    ${buildAndPushBody}
  '';

  prepareUpdateBranch = pkgs.writeShellScript "buildbot-prepare-update-branch" ''
    set -euo pipefail
    (
      flock -x 9
      if [ -d "${flakeDir}/.git" ]; then
        cd ${flakeDir}
        git fetch --prune origin
      else
        git clone --branch main ${flakeRepo} ${flakeDir}
      fi
    ) 9>"${lockFile}"
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

  masterCfg = pkgs.writeText "master.cfg" ''
    from buildbot.plugins import *

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

    all_builder_names = build_builder_names + ['flake-update']

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
    "${self}/modules/nixos/server/attic-setup.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "buildbot" ];

    topology.self.services.${serviceName} = {
      name = "Buildbot";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    systemd.tmpfiles.settings."10-buildbot" = builtins.listToAttrs (
      map
        (path: {
          name = "/home/buildbot/${path}";
          value = {
            d = {
              group = "buildbot";
              user = "buildbot";
              mode = "0750";
            };
          };
        }) [
        "/flake"
        "/master"
      ]
    );

    users = {
      persistentIds.${serviceName} = confLib.mkIds 1002; # must be a normal user
      users.${serviceName} = {
        extraGroups = [ "builder" ];
        subUidRanges = [
          {
            count = 65534;
            startUid = 100001;
          }
        ];
        subGidRanges = [
          {
            count = 999;
            startGid = 1001;
          }
        ];
      };
    };

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/";
        expectedBodyRegex = "Buildbot Web UI";
        network = "local-${config.node.name}";
      };
    };

    nix.gc = {
      automatic = true;
      dates = lib.mkForce "20:00";
      options = lib.mkForce "--delete-older-than 15w";
    };

    sops.secrets = {
      buildbot-github-key = {
        inherit sopsFile;
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
      buildbot-age-key = {
        inherit sopsFile;
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
      buildbot-github-token = {
        inherit sopsFile;
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
    };

    programs.ssh.extraConfig = lib.mkAfter ''
      Host github.com
          IdentityFile ${config.sops.secrets.buildbot-github-key.path}
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new
    '';

    nix.settings.trusted-users = [ "buildbot" ];

    services.buildbot-master = {
      enable = true;
      inherit masterCfg;
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

    systemd.services.buildbot-master = {
      environment.SOPS_AGE_KEY_FILE = config.sops.secrets.buildbot-age-key.path;
      serviceConfig = {
        MemoryMax = "20G";
        Restart = "always";
      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = "/home/buildbot"; user = "buildbot"; group = "buildbot"; mode = "0750"; }
    ];


    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
      ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; proxyWebsockets = true; oauth2 = true; oauth2Groups = [ "buildbot_access" ]; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; proxyWebsockets = true; oauth2Groups = [ "buildbot_access" ]; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
