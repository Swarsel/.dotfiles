{ lib, config, ... }:
{
  programs = {
    mbsync = lib.mkIf (!config.swarselsystems.isPublic) {
      enable = true;
    };
    msmtp = lib.mkIf (!config.swarselsystems.isPublic) {
      enable = true;
    };
    mu = lib.mkIf (!config.swarselsystems.isPublic) {
      enable = true;
    };
  };

  services.mbsync = lib.mkIf (!config.swarselsystems.isPublic) {
    enable = true;
  };
  # this is needed so that mbsync can use the passwords from sops
  systemd.user.services.mbsync.Unit.After = lib.mkIf (!config.swarselsystems.isPublic) [ "sops-nix.service" ];

  accounts = {
    email = lib.mkIf (!config.swarselsystems.isPublic) {
      maildirBasePath = "Mail";
      accounts = {
        leon = {
          primary = true;
          address = "leon.schwarzaeugl@gmail.com";
          userName = "leon.schwarzaeugl@gmail.com";
          realName = "Leon Schwarzäugl";
          passwordCommand = "cat ${config.sops.secrets.leon.path}";
          gpg = {
            key = "0x76FD3810215AE097";
            signByDefault = true;
          };
          imap.host = "imap.gmail.com";
          smtp.host = "smtp.gmail.com";
          mu.enable = true;
          msmtp = {
            enable = true;
          };
          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "both";
            patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail" ];
            extraConfig = {
              channel = {
                Sync = "All";
              };
              account = {
                Timeout = 120;
                PipelineDepth = 1;
              };
            };
          };
        };

        swarsel = lib.mkIf (!config.swarselsystems.isPublic) {
          address = "leon@swarsel.win";
          userName = "8227dc594dd515ce232eda1471cb9a19";
          realName = "Leon Schwarzäugl";
          passwordCommand = "cat ${config.sops.secrets.swarselmail.path}";
          smtp = {
            host = "in-v3.mailjet.com";
            port = 587;
            tls = {
              enable = true;
              useStartTls = true;
            };
          };
          mu.enable = false;
          msmtp = {
            enable = true;
          };
          mbsync = {
            enable = false;
          };
        };

        nautilus = lib.mkIf (!config.swarselsystems.isPublic) {
          primary = false;
          address = "nautilus.dw@gmail.com";
          userName = "nautilus.dw@gmail.com";
          realName = "Nautilus";
          passwordCommand = "cat ${config.sops.secrets.nautilus.path}";
          imap.host = "imap.gmail.com";
          smtp.host = "smtp.gmail.com";
          msmtp.enable = true;
          mu.enable = true;
          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "both";
            patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail" ];
            extraConfig = {
              channel = {
                Sync = "All";
              };
              account = {
                Timeout = 120;
                PipelineDepth = 1;
              };
            };
          };
        };

        mrswarsel = lib.mkIf (!config.swarselsystems.isPublic) {
          primary = false;
          address = "mrswarsel@gmail.com";
          userName = "mrswarsel@gmail.com";
          realName = "Swarsel";
          passwordCommand = "cat ${config.sops.secrets.mrswarsel.path}";
          imap.host = "imap.gmail.com";
          smtp.host = "smtp.gmail.com";
          msmtp.enable = true;
          mu.enable = true;
          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "both";
            patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail" ];
            extraConfig = {
              channel = {
                Sync = "All";
              };
              account = {
                Timeout = 120;
                PipelineDepth = 1;
              };
            };
          };
        };

      };
    };
  };
}
