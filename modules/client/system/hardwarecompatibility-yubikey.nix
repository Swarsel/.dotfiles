{
  flake.modules = {
    nixos.hardwarecompatibility-yubikey =
      {
        lib,
        config,
        confLib,
        pkgs,
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
              authfile = pkgs.writeText "u2f-mappings" (
                lib.concatStrings [
                  mainUser
                  cfg1
                  cfg2
                ]
              );
            };
          };

          environment.systemPackages = with pkgs; [
            kdePackages.ksshaskpass
          ];
        };
      };

    homeManager = {
      yubikey =
        {
          lib,
          config,
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
          systemd.user.services.yubikey-touch-detector = {
            Unit = {
              Description = "Detects when your YubiKey is waiting for a touch";
              Requires = [ "yubikey-touch-detector.socket" ];
            };
            Service = {
              ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
              EnvironmentFile = "-%E/yubikey-touch-detector/service.conf";
            };
            Install = {
              Also = [ "yubikey-touch-detector.socket" ];
              WantedBy = [ "default.target" ];
            };
          };
          systemd.user.sockets.yubikey-touch-detector = {
            Unit = {
              Description = "Unix socket activation for YubiKey touch detector service";
            };
            Socket = {
              ListenStream = "%t/yubikey-touch-detector.socket";
              RemoveOnStop = true;
            };
            Install = {
              WantedBy = [ "sockets.target" ];
            };
          };
        };
      };
    };
  };
}
