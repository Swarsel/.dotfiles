{
  flake.modules = {
    homeManager.ssh =
      {
        config,
        lib,
        confLib,
        nixosConfig ? null,
        ...
      }:
      {
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
            // confLib.getConfig.repo.secrets.common.ssh.hosts;
          };
        }
        // lib.optionalAttrs (nixosConfig == null) {
          sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
            builder-key = {
              mode = "0600";
              path = "${config.home.homeDirectory}/.ssh/builder";
            };
          };
        };
      };
    nixos.ssh =
      {
        self,
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
                (self + /files/public/ssh/yubikey.pub)
                (self + /files/public/ssh/magicant.pub)
                # (lib.mkIf config.swarselsystems.isBastionTarget (self + /files/public/ssh/jump.pub))
              ];
              root.openssh.authorizedKeys.keyFiles = [
                (self + /files/public/ssh/yubikey.pub)
                (self + /files/public/ssh/magicant.pub)
                # (lib.mkIf config.swarselsystems.isBastionTarget (self + /files/public/ssh/jump.pub))
              ];
            };
            persistentIds = {
              sshd = confLib.mkIds 979;
            };
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
