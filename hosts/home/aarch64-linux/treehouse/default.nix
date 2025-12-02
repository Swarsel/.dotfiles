{ self, pkgs, ... }:
{

  imports = [
    "${self}/modules/home"
  ];

  services.xcape = {
    enable = true;
    mapExpression = {
      Control_L = "Escape";
    };
  };

  home.packages = with pkgs; [
    attic-client
  ];
  # programs.zsh.initContent = "
  #   export GPG_TTY=\"$(tty)\"
  # export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  # gpgconf --launch gpg-agent
  #       ";
  swarselmodules.pii = true;

  swarselsystems = {
    isLaptop = false;
    isNixos = false;
    wallpaper = self + /files/wallpaper/surfacewp.png;
  };

  swarselprofiles = {
    dgxspark = true;
  };

}
