{ self, lib, config, withHomeManager, confLib, ... }:
{
  config = {
    swarselsystems.enabledServerModules = [ "ssh" ];
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
}
