{
  flake-file.inputs.yubikey-touch-alarm = {
    inputs = {
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "pre-commit-hooks";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "git+ssh://forgejo@swagit.swarsel.win:2222/swarsel/yubikey-touch-alarm";
  };

  flake.modules.nixos.hardwarecompatibility-yubikey =
    {
      root,
      inputs,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit (config.swarselsystems) mainUser;
      inherit (config.repo.secrets.common.yubikeys) cfg1 cfg2 cfg3;
      inherit (config.lib.stylix) colors;
    in
    {
      imports = [ inputs.yubikey-touch-alarm.nixosModules.default ];

      config = {

        users.persistentIds.pcscd = confLib.mkIds 956;
        services = {
          gnome.gcr-ssh-agent.enable = false;
          pcscd.enable = true;
          udev.packages = with pkgs; [
            yubikey-personalization
          ];
          yubikey-agent.enable = false;
          yubikey-touch-alarm = {
            enable = true;
            image = root "files/icons/smaaaash.png";
            popupDelay = 2;
            sound = root "files/audio/jetztgehtslos.flac";
            soundDelay = 8;
            soundRepeats = 30;
            style = {
              background = "alpha(#${colors.base00}, 0.8)";
              font = config.stylix.fonts.monospace.name;
              foreground = "#${colors.base05}";
            };
          };
        };
        programs = {
          ssh = {
            startAgent = false; # yes we want this to use FIDO2 keys
            # enableAskPassword = true;
            # askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
          };
          yubikey-touch-detector = {
            enable = true;
            libnotify = false;
          };
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
        systemd.user.services.yubikey-touch-detector = {
          after = [ "gpg-agent-ssh.socket" ];
          environment.SSH_AUTH_SOCK = "%t/gnupg/S.gpg-agent.ssh";
          partOf = [ "gpg-agent-ssh.socket" ];
        };
      };
    };
}
