{ self, lib, config, withHomeManager, confLib, ... }:
{
  config = {
    swarselsystems.enabledServerModules = [ "bastion" ];

    users = {
      persistentIds.jump = confLib.mkIds 1001;
      groups = {
        jump = { };
      };
      users = {
        jump = {
          autoSubUidGidRange = false;
          isNormalUser = true;
          useDefaultShell = true;
          group = lib.mkForce "jump";
          createHome = lib.mkForce true;
          openssh.authorizedKeys.keyFiles = [
            (self + /secrets/public/ssh/yubikey.pub)
            (self + /secrets/public/ssh/magicant.pub)
            (self + /secrets/public/ssh/builder.pub)
          ];
        };
      };
    };


    services.openssh = {
      enable = true;
      startWhenNeeded = lib.mkForce false;
      authorizedKeysInHomedir = false;
      extraConfig = ''
        Match User jump
          PermitTTY no
          X11Forwarding no
          PermitTunnel no
          GatewayPorts no
          AllowAgentForwarding no
      '';
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = lib.mkDefault "no";
        AllowUsers = [
          "jump"
        ];
      };
      hostKeys = lib.mkIf (!(builtins.elem "ssh" config.swarselsystems.enabledServerModules)) [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  } // lib.optionalAttrs withHomeManager {

    home-manager.users.jump.config = {
      home.stateVersion = lib.mkDefault "23.05";
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            forwardAgent = false;
          };
        } // config.repo.secrets.local.ssh.hosts;
      };
    };
  };
}
