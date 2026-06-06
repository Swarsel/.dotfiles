{
  flake.modules.nixos.hardwarecompatibility-ledger = { pkgs, ... }: {
    config = {
      hardware.ledger.enable = true;

      services.udev.packages = with pkgs; [
        ledger-udev-rules
      ];
    };
  };
}
