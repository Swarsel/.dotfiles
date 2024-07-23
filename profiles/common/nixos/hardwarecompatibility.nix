{ pkgs, ... }:
{
  programs.ssh.startAgent = false;

  services.pcscd.enable = true;

  hardware.ledger.enable = true;

  services.udev.packages = with pkgs; [
    yubikey-personalization
    ledger-udev-rules
  ];
}
