{ self, lib, config, ... }:
{
  options.swarselmodules.server.bastion = lib.mkEnableOption "enable bastion on server";
  config = lib.mkIf config.swarselmodules.server.bastion {

    users = {
      groups = {
        jump = { };
      };
      users = {
        "jump" = {
          isNormalUser = true;
          useDefaultShell = true;
          group = lib.mkForce "jump";
          createHome = lib.mkForce true;
          openssh.authorizedKeys.keyFiles = [
            (self + /secrets/keys/ssh/yubikey.pub)
            (self + /secrets/keys/ssh/magicant.pub)
            (self + /secrets/keys/ssh/builder.pub)
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
      hostKeys = lib.mkIf (!config.swarselmodules.server.ssh) [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    home-manager.users.jump.config = {
      home.stateVersion = lib.mkDefault "23.05";
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            forwardAgent = false;
          };
        } // config.repo.secrets.local.ssh.hosts;
      };
    };
  };
}
