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
          description = "Hosts to configure from the personal ssh host list; null for all.";
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
              rekey.keyPrefix = confLib.static.sharedSecrets.clients;
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
      let
        keyFiles = [
          (root "files/public/ssh/yubikey.pub")
          (root "files/public/ssh/magicant.pub")
        ];
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "ssh" ];
          users = {
            users = {
              "${config.swarselsystems.mainUser}".openssh.authorizedKeys.keyFiles =
                lib.mkIf withHomeManager keyFiles;
              root.openssh.authorizedKeys.keyFiles = keyFiles;
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
              ]
              ++
                lib.optional config.users.users.${config.swarselsystems.mainUser}.enable
                  config.swarselsystems.mainUser;
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
