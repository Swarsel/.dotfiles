{ pkgs, ... }:
{
  hardware.ledger.enable = true;

  services.udev.packages = with pkgs; [
    ledger-udev-rules
  ];

}
