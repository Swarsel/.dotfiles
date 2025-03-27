{ self, config, pkgs, ... }:
{

  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    zjstatus
  ];

  xdg.configFile = {
    "zellij/config.kdl".text = import "${self}/programs/zellij/config.kdl.nix" { inherit config; };
    "zellij/layouts/default.kdl".text = import "${self}/programs/zellij/layouts/default.kdl.nix" { inherit config pkgs; };
  };

}
