{
  flake.modules.nixos.remotebuild =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir isClient mainUser;
      clientsSecrets = confLib.static.sharedSecrets.clients;
    in
    {
      config = {

        sops.secrets = {
          builder-key = lib.mkIf isClient {
            mode = "0600";
            owner = mainUser;
            path = "${homeDir}/.ssh/builder";
            rekey.keyPrefix = clientsSecrets;
          };
          nixbuild-net-key = {
            mode = "0600";
            owner = mainUser;
            path = "${homeDir}/.ssh/nixbuild-net";
            rekey.keyPrefix = clientsSecrets;
          };
        };
        programs.ssh = {
          extraConfig = ''
            Host eu.nixbuild.net
              ConnectTimeout 5
              PubkeyAcceptedKeyTypes ssh-ed25519
              ServerAliveInterval 60
              IPQoS throughput
              IdentityFile ${config.sops.secrets.nixbuild-net-key.path}
          ''
          + lib.optionalString isClient ''
            Host ${config.repo.secrets.common.builder1-ip}
              ConnectTimeout 2
              User ${mainUser}
              IdentityFile ${config.sops.secrets.builder-key.path}

            Host ${globals.hosts.belchsfactory.wanAddress4}
              ConnectTimeout 5
              ProxyJump ${globals.hosts.liliputsteps.wanAddress4}
              User builder
              IdentityFile ${config.sops.secrets.builder-key.path}

            Host ${globals.hosts.liliputsteps.wanAddress4}
              ConnectTimeout 2
              User jump
              IdentityFile ${config.sops.secrets.builder-key.path}
          '';
          knownHosts = lib.mkMerge [
            {
              nixbuild = {
                hostNames = [ "eu.nixbuild.net" ];
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
              };
            }
            (lib.mkIf isClient {
              builder1 = {
                hostNames = [ config.repo.secrets.common.builder1-ip ];
                publicKey = config.repo.secrets.common.builder1-pubHostKey;
              };
              builder2 = {
                hostNames = [ globals.hosts.belchsfactory.wanAddress4 ];
                publicKey = config.repo.secrets.common.builder2-pubHostKey;
              };
              jump = {
                hostNames = [ globals.hosts.liliputsteps.wanAddress4 ];
                publicKey = config.repo.secrets.common.jump-pubHostKey;
              };
            })
          ];
        };
        nix = {
          buildMachines = lib.optionals isClient [
            {
              hostName = config.repo.secrets.common.builder1-ip;
              maxJobs = 20;
              speedFactor = 10;
              system = "aarch64-linux";
            }
            {
              hostName = globals.hosts.belchsfactory.wanAddress4;
              maxJobs = 4;
              protocol = "ssh-ng";
              speedFactor = 2;
              system = "aarch64-linux";
            }
            {
              hostName = "eu.nixbuild.net";
              maxJobs = 100;
              speedFactor = 2;
              supportedFeatures = [
                "benchmark"
                "big-parallel"
              ];
              system = "x86_64-linux";
            }
          ];
          distributedBuilds = true;
          settings.builders-use-substitutes = true;
        };
      };
    };
}
