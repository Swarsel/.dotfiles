{ self, lib, config, ... }:
{
  options.swarselmodules.server.ssh = lib.mkEnableOption "enable ssh on server";
  config = lib.mkIf config.swarselmodules.server.ssh {
    services.openssh = {
      enable = true;
      startWhenNeeded = lib.mkForce false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "yes";
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
    users.users."${config.swarselsystems.mainUser}".openssh.authorizedKeys.keyFiles = [
      (self + /secrets/keys/ssh/yubikey.pub)
      (self + /secrets/keys/ssh/magicant.pub)
      # (lib.mkIf config.swarselsystems.isBastionTarget (self + /secrets/keys/ssh/jump.pub))
    ];
    users.users.root.openssh.authorizedKeys.keyFiles = [
      (self + /secrets/keys/ssh/yubikey.pub)
      (self + /secrets/keys/ssh/magicant.pub)
      # (lib.mkIf config.swarselsystems.isBastionTarget (self + /secrets/keys/ssh/jump.pub))
    ];
    security.sudo.extraConfig = ''
      Defaults    env_keep+=SSH_AUTH_SOCK
    '';
  };
}
