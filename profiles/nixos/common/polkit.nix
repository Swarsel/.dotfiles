_:
{

  security = {
    pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      swaylock.u2fAuth = true;
      swaylock.fprintAuth = false;
    };
    polkit.enable = true;

    sudo.extraConfig = ''
      Defaults    env_keep+=SSH_AUTH_SOCK
    '';
  };

}
