{ self, lib, config, pkgs, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "buildbot"; port = 8010; }) serviceName servicePort serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer dnsServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) mainUser sopsFile;

  nixosHostsForArch = arch:
    let dir = self + "/hosts/nixos/${arch}";
    in if builtins.pathExists dir then builtins.attrNames (builtins.readDir dir) else [ ];

  allNixosHosts = nixosHostsForArch "aarch64-linux" ++ nixosHostsForArch "x86_64-linux";

  buildbotHome = config.services.buildbot-master.home;
  flakeDir = "${buildbotHome}/flake";
  flakeRepo = "https://github.com/Swarsel/.dotfiles.git";
  lockFile = "${flakeDir}/.flake-update.lock";

  buildAndPush = pkgs.writeShellScript "buildbot-build-and-push" ''
    set -euo pipefail
    HOST="$1"

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

    echo "=== Building nixosConfiguration: $HOST ==="

    result=$(${lib.getExe config.nix.package} build \
      "path:${flakeDir}#nixosConfigurations.$HOST.config.system.build.toplevel" \
      --no-link \
      --max-jobs 3 \
      --print-out-paths \
      --accept-flake-config)

    echo "Build output: $result"
    echo "=== Pushing $HOST to binary cache ==="

    echo "$result" | xargs ${lib.getExe pkgs.attic-client} push ${mainUser}

    echo "=== Successfully built and pushed $HOST ==="
  '';

  masterCfg = pkgs.writeText "master.cfg" ''
    from buildbot.plugins import *

    c = BuildmasterConfig = {}

    c['workers'] = [worker.LocalWorker('local-worker', max_builds=1)]
    c['protocols'] = {'pb': {'port': 9989}}

    hosts = ${builtins.toJSON allNixosHosts}

    builders = []
    all_builder_names = []

    for host in hosts:
        f = util.BuildFactory()
        f.addStep(steps.ShellCommand(
            name='build-and-push',
            command=['${buildAndPush}', host],
            timeout=7200,
        ))
        builders.append(util.BuilderConfig(
            name=f'build-{host}',
            workernames=['local-worker'],
            factory=f,
        ))
        all_builder_names.append(f'build-{host}')

    c['builders'] = builders

    c['schedulers'] = [
        schedulers.Periodic(
            name='nightly',
            builderNames=all_builder_names,
            periodicBuildTimer=86400,
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
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };

  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

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
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
    };

    swarselmodules.server.attic-setup = true;

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
      ];
      pythonPackages = _p: [
        pkgs.buildbot-worker
      ];
    };

    systemd.services.buildbot-master = {
      environment.SOPS_AGE_KEY_FILE = config.sops.secrets.buildbot-age-key.path;
      serviceConfig = {
        MemoryMax = "16G";
        Restart = "always";
      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = "/home/buildbot"; user = "buildbot"; group = "buildbot"; mode = "0750"; }
    ];

    nodes = {
      ${idmServer} =
        {
          services.kanidm.provision = {
            groups = {
              "buildbot.access" = { };
            };
            systems.oauth2.oauth2-proxy = {
              scopeMaps = {
                "buildbot.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
              claimMaps.groups = {
                valuesByGroup = {
                  "buildbot.access" = [ "buildbot_access" ];
                };
              };
            };
          };
        };
      ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; proxyWebsockets = true; oauth2 = true; oauth2Groups = [ "buildbot_access" ]; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; proxyWebsockets = true; oauth2Groups = [ "buildbot_access" ]; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
