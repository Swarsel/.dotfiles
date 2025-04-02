{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.passwordstore = lib.mkEnableOption "passwordstore settings";
  config = lib.mkIf config.swarselsystems.modules.passwordstore {
    programs.password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
      };
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    };
  };
}
