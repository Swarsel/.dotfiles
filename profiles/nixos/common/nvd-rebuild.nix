{ pkgs, ... }:
{
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --color=always --nix-bin-dir=${pkgs.nix}/bin diff \
           /run/current-system "$systemConfig"
    '';
  };
}
