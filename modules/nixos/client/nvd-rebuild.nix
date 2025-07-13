{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.nvd = lib.mkEnableOption "nvd config";
  config = lib.mkIf config.swarselsystems.modules.nvd {

    environment.systemPackages = [
      pkgs.nvd
    ];

    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${pkgs.nvd}/bin/nvd --color=always --nix-bin-dir=${pkgs.nix}/bin diff \
             /run/current-system "$systemConfig"
      '';
    };
  };
}
