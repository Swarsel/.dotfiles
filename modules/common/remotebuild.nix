{
  flake.modules.nixos.remotebuild =
    {
      config,
      lib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir isClient mainUser;
    in
    {
      config = {

        sops.secrets = {
          builder-key = lib.mkIf isClient {
            mode = "0600";
            owner = mainUser;
            path = "${homeDir}/.ssh/builder";
          };
          nixbuild-net-key = {
            mode = "0600";
            owner = mainUser;
            path = "${homeDir}/.ssh/nixbuild-net";
          };
        };
        programs.ssh = {
          extraConfig = ''
            Host eu.nixbuild.net
              ConnectTimeout 1
              PubkeyAcceptedKeyTypes ssh-ed25519
              ServerAliveInterval 60
              IPQoS throughput
              IdentityFile ${config.sops.secrets.nixbuild-net-key.path}
          ''
          + lib.optionalString isClient ''
            Host ${config.repo.secrets.common.builder1-ip}
              ConnectTimeout 1
              User ${mainUser}
              IdentityFile ${config.sops.secrets.builder-key.path}

            Host ${globals.hosts.belchsfactory.wanAddress4}
              ConnectTimeout 5
              ProxyJump ${globals.hosts.liliputsteps.wanAddress4}
              User builder
              IdentityFile ${config.sops.secrets.builder-key.path}

            Host ${globals.hosts.liliputsteps.wanAddress4}
              ConnectTimeout 1
              User jump
              IdentityFile ${config.sops.secrets.builder-key.path}
          '';
          knownHosts = {
            builder1 = lib.mkIf isClient {
              hostNames = [ config.repo.secrets.common.builder1-ip ];
              publicKey = config.repo.secrets.common.builder1-pubHostKey;
            };
            builder2 = lib.mkIf isClient {
              hostNames = [ globals.hosts.belchsfactory.wanAddress4 ];
              publicKey = config.repo.secrets.common.builder2-pubHostKey;
            };
            jump = lib.mkIf isClient {
              hostNames = [ globals.hosts.liliputsteps.wanAddress4 ];
              publicKey = config.repo.secrets.common.jump-pubHostKey;
            };
            nixbuild = {
              hostNames = [ "eu.nixbuild.net" ];
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
            };
          };
        };
        nix = {
          buildMachines = [
            (lib.mkIf isClient {
              hostName = config.repo.secrets.common.builder1-ip;
              maxJobs = 20;
              speedFactor = 10;
              system = "aarch64-linux";
            })
            (lib.mkIf isClient {
              hostName = globals.hosts.belchsfactory.wanAddress4;
              maxJobs = 4;
              protocol = "ssh-ng";
              speedFactor = 2;
              system = "aarch64-linux";
            })
            (lib.mkIf isClient {
              hostName = "eu.nixbuild.net";
              maxJobs = 100;
              speedFactor = 2;
              supportedFeatures = [
                "benchmark"
                "big-parallel"
              ];
              system = "x86_64-linux";
            })
          ];
          distributedBuilds = true;
          settings.builders-use-substitutes = true;
        };
      };
    };
}
