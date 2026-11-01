{
  flake.modules = {
    homeManager.ssh =
      {
        config,
        lib,
        options,
        confLib,
        nixosConfig ? null,
        ...
      }:
      {
        options.swarselsystems.sshHosts = lib.mkOption {
          default = null;
          description = "Names of the hosts from the personal ssh host list to configure; null configures all of them.";
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
        };
        config = {
          swarselsystems.enabledHomeModules = [ "ssh" ];
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            extraConfig = ''
              SetEnv TERM=xterm-256color
              ServerAliveInterval 20
            '';
            includes = [ "~/.ssh/extra/*" ];
            settings = {
              "*" = {
                addKeysToAgent = "no";
                compression = false;
                controlMaster = "no";
                controlPath = "~/.ssh/master-%r@%n:%p";
                controlPersist = "no";
                forwardAgent = false;
                hashKnownHosts = false;
                serverAliveCountMax = 3;
                serverAliveInterval = 0;
                userKnownHostsFile = "~/.ssh/known_hosts";
              };
            }
            // (
              let
                inherit (confLib.getConfig.repo.secrets.common.ssh) hosts;
              in
              if config.swarselsystems.sshHosts == null then
                hosts
              else
                lib.getAttrs config.swarselsystems.sshHosts hosts
            );
          };
        }
        // lib.optionalAttrs (nixosConfig == null && options ? sops) {
          sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
            builder-key = {
              mode = "0600";
              path = "${config.home.homeDirectory}/.ssh/builder";
              sopsFile = confLib.static.clientsSopsFile;
            };
          };
        };
      };
    nixos.ssh =
      {
        root,
        config,
        lib,
        confLib,
        withHomeManager,
        ...
      }:
      {
        config = {
          swarselsystems.enabledServerModules = [ "ssh" ];
          users = {
            users = {
              "${config.swarselsystems.mainUser}".openssh.authorizedKeys.keyFiles = lib.mkIf withHomeManager [
                (root "files/public/ssh/yubikey.pub")
                (root "files/public/ssh/magicant.pub")
                # (lib.mkIf config.swarselsystems.isBastionTarget (root "files/public/ssh/jump.pub"))
              ];
              root.openssh.authorizedKeys.keyFiles = [
                (root "files/public/ssh/yubikey.pub")
                (root "files/public/ssh/magicant.pub")
                # (lib.mkIf config.swarselsystems.isBastionTarget (root "files/public/ssh/jump.pub"))
              ];
            };
            persistentIds.sshd = confLib.mkIds 979;
          };
          services.openssh = {
            enable = true;
            hostKeys = [
              {
                path = "/etc/ssh/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];
            settings = {
              AllowUsers = [
                "root"
                config.swarselsystems.mainUser
              ];
              KbdInteractiveAuthentication = false;
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };
            startWhenNeeded = lib.mkForce false;
          };
          security.sudo.extraConfig = ''
            Defaults    env_keep+=SSH_AUTH_SOCK
          '';
        };
      };
  };
}
