{
  root,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{

  imports = [
    inputs.self.modules.homeManager.profile-base
    inputs.self.modules.homeManager.profile-dgxspark
  ]
  ++ lib.optionals (inputs.vbc-nix ? homeManagerModules) [
    inputs.vbc-nix.homeManagerModules.work-remote
    {
      services.work-remote.enable = true;
      nixpkgs.overlays = [ inputs.vbc-nix.overlays.default ];
    }
  ];

  swarselsystems = {
    isLaptop = false;
    wallpaper = root "files/wallpaper/landscape/surfacewp.png";
  };

  services.xcape = {
    enable = true;
    mapExpression.Control_L = "Escape";
  };

  programs = {
    git.signing = {
      format = lib.mkForce "ssh";
      key = lib.mkForce "${config.home.homeDirectory}/.ssh/id_rsa.pub";
    };
    tmux.shell = lib.mkForce (lib.getExe pkgs.bash);
    zellij.settings.default_shell = lib.mkForce "bash";
  };

  home.packages = with pkgs; [
    attic-client
  ];

  nix.settings.max-jobs = lib.mkForce "auto";

}
