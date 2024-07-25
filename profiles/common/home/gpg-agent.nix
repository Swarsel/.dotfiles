{ pkgs, ... }:
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry.gtk2;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    extraConfig = ''
      allow-loopback-pinentry
      allow-emacs-pinentry
    '';
  };
}
