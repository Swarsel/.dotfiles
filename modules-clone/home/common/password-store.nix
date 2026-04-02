{ lib, config, pkgs, ... }:
{
  options.swarselmodules.passwordstore = lib.mkEnableOption "passwordstore settings";
  config = lib.mkIf config.swarselmodules.passwordstore {
    programs.password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
      };
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    };
  };
}
