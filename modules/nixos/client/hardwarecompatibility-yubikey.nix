{ lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) mainUser;
  inherit (config.repo.secrets.common.yubikeys) cfg1 cfg2;
in
{
  options.swarselmodules.yubikey = lib.mkEnableOption "yubikey config";
  config = lib.mkIf config.swarselmodules.yubikey {
    programs.ssh = {
      startAgent = false; # yes we want this to use FIDO2 keys
      # enableAskPassword = true;
      # askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
    };
    services = {
      gnome.gcr-ssh-agent.enable = false;
      yubikey-agent.enable = false;
      pcscd.enable = true;

      udev.packages = with pkgs; [
        yubikey-personalization
      ];
    };

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

    environment.systemPackages = with pkgs; [
      kdePackages.ksshaskpass
    ];
  };
}
