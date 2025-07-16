{ self, lib, config, pkgs, ... }:
{
  options.swarselmodules.zellij = lib.mkEnableOption "zellij settings";
  config = lib.mkIf config.swarselmodules.zellij {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [
      zjstatus
    ];

    xdg.configFile = {
      "zellij/config.kdl".text = import "${self}/files/zellij/config.kdl.nix" { inherit config; };
      "zellij/layouts/default.kdl".text = import "${self}/files/zellij/layouts/default.kdl.nix" { inherit config pkgs; };
    };
  };

}
