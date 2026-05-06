{ self, pkgs, ... }:
{

  imports = [
    "${self}/modules/home"
    "${self}/profiles/home/dgxspark"
    "${self}/modules/nixos/common/pii.nix"
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
  swarselsystems = {
    isLaptop = false;
    isNixos = false;
    wallpaper = self + /files/wallpaper/landscape/surfacewp.png;
  };

}
