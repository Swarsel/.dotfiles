{
  flake.modules = {
    homeManager = {
      yubikey =
        {
          config,
          lib,
          confLib,
          type,
          nixosConfig ? null,
          ...
        }:
        let
          inherit (config.swarselsystems) homeDir;
        in
        {

          config = {
            swarselsystems.enabledHomeModules = [ "yubikey" ];
            pam.yubico.authorizedYubiKeys =
              lib.mkIf ((nixosConfig != null) && !config.swarselsystems.isPublic)
                {
                  ids = [
                    confLib.getConfig.repo.secrets.common.yubikeys.dev1
                    confLib.getConfig.secrets.common.yubikeys.dev2
                  ];
                };
          }
          // lib.optionalAttrs (type != "nixos") {
            sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
              u2f-keys = {
                path = "${homeDir}/.config/Yubico/u2f_keys";
              };
            };
          };
        };

      yubikey-touch-detector = { pkgs, ... }: {
        config = {
          swarselsystems.enabledHomeModules = [ "yubikeytouch" ];
          systemd = {
            user = {
              services.yubikey-touch-detector = {
                Install = {
                  Also = [ "yubikey-touch-detector.socket" ];
                  WantedBy = [ "default.target" ];
                };
                Service = {
                  EnvironmentFile = "-%E/yubikey-touch-detector/service.conf";
                  ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
                };
                Unit = {
                  Description = "Detects when your YubiKey is waiting for a touch";
                  Requires = [ "yubikey-touch-detector.socket" ];
                };
              };
              sockets.yubikey-touch-detector = {
                Install = {
                  WantedBy = [ "sockets.target" ];
                };
                Socket = {
                  ListenStream = "%t/yubikey-touch-detector.socket";
                  RemoveOnStop = true;
                };
                Unit = {
                  Description = "Unix socket activation for YubiKey touch detector service";
                };
              };
            };
          };
        };
      };
    };
    nixos.hardwarecompatibility-yubikey =
      {
        config,
        lib,
        pkgs,
        confLib,
        ...
      }:
      let
        inherit (config.swarselsystems) mainUser;
        inherit (config.repo.secrets.common.yubikeys) cfg1 cfg2;
      in
      {
        config = {

          users.persistentIds = {
            pcscd = confLib.mkIds 956;
          };
          services = {
            gnome.gcr-ssh-agent.enable = false;
            pcscd.enable = true;
            udev.packages = with pkgs; [
              yubikey-personalization
            ];
            yubikey-agent.enable = false;
          };
          programs.ssh = {
            startAgent = false; # yes we want this to use FIDO2 keys
            # enableAskPassword = true;
            # askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
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
                ]
              );
              cue = true; # prints a message that a touch is requrired
              interactive = false; # displays a prompt BEFORE asking for presence
              origin = "pam://${mainUser}"; # make the keys work on all machines
            };
          };
        };
      };
  };
}
