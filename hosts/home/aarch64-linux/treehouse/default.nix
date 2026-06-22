{
  self,
  inputs,
  pkgs,
  ...
}:
{

  imports = [
    inputs.self.modules.homeManager.profile-base
    inputs.self.modules.homeManager.profile-dgxspark
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
    wallpaper = self + /files/wallpaper/landscape/surfacewp.png;
  };

}
