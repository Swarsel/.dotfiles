{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.yubikey = lib.mkEnableOption "yubikey config";
  config = lib.mkIf config.swarselsystems.modules.yubikey {
    programs.ssh.startAgent = false;

    services.pcscd.enable = false;

    hardware.gpgSmartcards.enable = true;

    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];

  };
}
