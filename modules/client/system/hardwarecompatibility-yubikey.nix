{
  flake.modules.nixos.hardwarecompatibility-yubikey =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit (config.swarselsystems) mainUser;
      inherit (config.repo.secrets.common.yubikeys) cfg1 cfg2 cfg3;
    in
    {
      config = {

        users.persistentIds.pcscd = confLib.mkIds 956;
        services = {
          gnome.gcr-ssh-agent.enable = false;
          pcscd.enable = true;
          udev.packages = with pkgs; [
            yubikey-personalization
          ];
          yubikey-agent.enable = false;
        };
        programs = {
          ssh = {
            startAgent = false; # yes we want this to use FIDO2 keys
            # enableAskPassword = true;
            # askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
          };
          yubikey-touch-detector.enable = true;
        };
        environment.systemPackages = with pkgs; [
          kdePackages.ksshaskpass
        ];
        hardware.gpgSmartcards.enable = true;
        security.pam.u2f = {
          enable = true;
          control = "sufficient";
          settings = {
            authfile = pkgs.writeText "u2f-mappings" (
              lib.concatStrings [
                mainUser
                cfg1
                cfg2
                cfg3
              ]
            );
            cue = true; # prints a message that a touch is requrired
            interactive = false; # displays a prompt BEFORE asking for presence
            origin = "pam://${mainUser}"; # make the keys work on all machines
          };
        };
      };
    };
}
