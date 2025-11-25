{ config, pkgs, lib, ... }:
{
  options.swarselmodules.bash = lib.mkEnableOption "bash settings";
  config = lib.mkIf config.swarselmodules.bash {

    programs.bash = {
      bashrcExtra = ''
        export PATH="${pkgs.nix}/bin:$PATH"
      '';
    };
  };
}
