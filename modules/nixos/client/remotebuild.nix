{ lib, config, globals, ... }:
let
  inherit (config.swarselsystems) homeDir mainUser isClient;
in
{
  options.swarselmodules.remotebuild = lib.mkEnableOption "enable remote builds on this machine";
  config = lib.mkIf config.swarselmodules.remotebuild {

    sops.secrets = {
      builder-key = lib.mkIf isClient { owner = mainUser; path = "${homeDir}/.ssh/builder"; mode = "0600"; };
      nixbuild-net-key = { owner = mainUser; path = "${homeDir}/.ssh/nixbuild-net"; mode = "0600"; };
    };

    nix = {
      settings.builders-use-substitutes = true;
      distributedBuilds = true;
      buildMachines = [
        (lib.mkIf isClient {
          hostName = config.repo.secrets.common.builder1-ip;
          system = "aarch64-linux";
          maxJobs = 20;
          speedFactor = 10;
        })
        (lib.mkIf isClient {
          hostName = globals.hosts.belchsfactory.wanAddress4;
          system = "aarch64-linux";
          maxJobs = 4;
          speedFactor = 2;
          protocol = "ssh-ng";
        })
        {
          hostName = "eu.nixbuild.net";
          system = "x86_64-linux";
          maxJobs = 100;
          speedFactor = 2;
          supportedFeatures = [ "big-parallel" ];
        }
      ];
    };
    programs.ssh = {
      knownHosts = {
        nixbuild = {
          hostNames = [ "eu.nixbuild.net" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
        builder1 = lib.mkIf isClient {
          hostNames = [ config.repo.secrets.common.builder1-ip ];
          publicKey = config.repo.secrets.common.builder1-pubHostKey;
        };
        jump = lib.mkIf isClient {
          hostNames = [ globals.hosts.liliputsteps.wanAddress4 ];
          publicKey = config.repo.secrets.common.jump-pubHostKey;
        };
        builder2 = lib.mkIf isClient {
          hostNames = [ globals.hosts.belchsfactory.wanAddress4 ];
          publicKey = config.repo.secrets.common.builder2-pubHostKey;
        };
      };
      extraConfig = ''
        Host eu.nixbuild.net
          ConnectTimeout 1
          PubkeyAcceptedKeyTypes ssh-ed25519
          ServerAliveInterval 60
          IPQoS throughput
          IdentityFile ${config.sops.secrets.nixbuild-net-key.path}
      '' + lib.optionalString isClient ''
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
    };
  };
}
