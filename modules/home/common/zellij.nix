{ self, lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.zellij = lib.mkEnableOption "zellij settings";
  config = lib.mkIf config.swarselsystems.modules.zellij {
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
  };

}
