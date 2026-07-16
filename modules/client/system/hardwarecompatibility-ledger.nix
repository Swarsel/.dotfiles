{
  flake.modules.nixos.hardwarecompatibility-ledger = { pkgs, ... }: {
    config = {
      services.udev.packages = with pkgs; [
        ledger-udev-rules
      ];
      hardware.ledger.enable = true;
    };
  };
}
