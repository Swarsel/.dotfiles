{ lib, config, pkgs, ... }:
{
  options.swarselmodules.nvd = lib.mkEnableOption "nvd config";
  config = lib.mkIf config.swarselmodules.nvd {

    environment.systemPackages = [
      pkgs.nvd
    ];

    # system.activationScripts.diff = {
    #   supportsDryActivation = true;
    #   text = ''
    #     ${pkgs.nvd}/bin/nvd --color=always --nix-bin-dir=${pkgs.nix}/bin diff \
    #          /run/current-system "$systemConfig"
    #   '';
    # };
  };
}
