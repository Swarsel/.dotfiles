{
  self,
  inputs,
  lib,
  pkgs,
  ...
}:
{

  imports = [
    inputs.self.modules.homeManager.profile-base
    inputs.self.modules.homeManager.profile-dgxspark
  ];

  swarselsystems = {
    isLaptop = false;
    wallpaper = self + /files/wallpaper/landscape/surfacewp.png;
  };

  services.xcape = {
    enable = true;
    mapExpression.Control_L = "Escape";
  };

  programs = {
    tmux.shell = lib.mkForce (lib.getExe pkgs.bash);
    zellij.settings.default_shell = lib.mkForce "bash";
  };

  home.packages = with pkgs; [
    attic-client
  ];

}
