{ pkgs, ... }:
{
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    };
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  };
}
