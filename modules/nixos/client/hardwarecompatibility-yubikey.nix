{ lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) mainUser;
  inherit (config.repo.secrets.common.yubikeys) cfg1 cfg2;
in
{
  options.swarselsystems.modules.yubikey = lib.mkEnableOption "yubikey config";
  config = lib.mkIf config.swarselsystems.modules.yubikey {
    programs.ssh.startAgent = false;

    services.pcscd.enable = false;

    hardware.gpgSmartcards.enable = true;

    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        interactive = false; # displays a prompt BEFORE asking for presence
        cue = true; # prints a message that a touch is requrired
        origin = "pam://${mainUser}"; # make the keys work on all machines
        authfile = pkgs.writeText "u2f-mappings" (lib.concatStrings [
          mainUser
          cfg1
          cfg2
        ]);
      };
    };

    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];

  };
}
