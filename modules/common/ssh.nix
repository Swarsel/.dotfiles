{
  flake.modules = {
    nixos.ssh = { self, lib, config, withHomeManager, confLib, ... }:
      {
        config = {
          swarselsystems.enabledServerModules = [ "ssh" ];
          services.openssh = {
            enable = true;
            startWhenNeeded = lib.mkForce false;
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "prohibit-password";
              AllowUsers = [
                "root"
                config.swarselsystems.mainUser
              ];
            };
            hostKeys = [
              {
                path = "/etc/ssh/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];
          };
          users = {
            persistentIds = {
              sshd = confLib.mkIds 979;
            };
            users = {
              "${config.swarselsystems.mainUser}".openssh.authorizedKeys.keyFiles = lib.mkIf withHomeManager [
                (self + /secrets/public/ssh/yubikey.pub)
                (self + /secrets/public/ssh/magicant.pub)
                # (lib.mkIf config.swarselsystems.isBastionTarget (self + /secrets/public/ssh/jump.pub))
              ];
              root.openssh.authorizedKeys.keyFiles = [
                (self + /secrets/public/ssh/yubikey.pub)
                (self + /secrets/public/ssh/magicant.pub)
                # (lib.mkIf config.swarselsystems.isBastionTarget (self + /secrets/public/ssh/jump.pub))
              ];
            };
          };
          security.sudo.extraConfig = ''
            Defaults    env_keep+=SSH_AUTH_SOCK
          '';
        };
      };

    homeManager.ssh = { lib, config, confLib, nixosConfig ? null, ... }: {
      config = {
        swarselsystems.enabledHomeModules = [ "ssh" ];
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = [ "~/.ssh/extra/*" ];
          extraConfig = ''
            SetEnv TERM=xterm-256color
            ServerAliveInterval 20
          '';
          settings = {
            "*" = {
              forwardAgent = false;
              addKeysToAgent = "no";
              compression = false;
              serverAliveInterval = 0;
              serverAliveCountMax = 3;
              hashKnownHosts = false;
              userKnownHostsFile = "~/.ssh/known_hosts";
              controlMaster = "no";
              controlPath = "~/.ssh/master-%r@%n:%p";
              controlPersist = "no";
            };
          } // confLib.getConfig.repo.secrets.common.ssh.hosts;
        };
      } // lib.optionalAttrs (nixosConfig == null) {
        sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
          builder-key = { path = "${config.home.homeDirectory}/.ssh/builder"; mode = "0600"; };
        };
      };
    };
  };
}
