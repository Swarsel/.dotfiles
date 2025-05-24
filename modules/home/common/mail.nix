{ lib, config, nix-secrets, ... }:
let
  secretsDirectory = builtins.toString nix-secrets;
  leonMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/leon";
  nautilusMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/nautilus";
  mrswarselMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/mrswarsel";
  swarselMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/swarsel";
  fullName = lib.swarselsystems.getSecret "${secretsDirectory}/info/fullname";
in
{
  options.swarselsystems.modules.mail = lib.mkEnableOption "mail settings";
  config = lib.mkIf config.swarselsystems.modules.mail {
    programs = {
      mbsync = {
        enable = true;
      };
      msmtp = {
        enable = true;
      };
      mu = {
        enable = true;
      };
    };

    services.mbsync = {
      enable = true;
    };
    # this is needed so that mbsync can use the passwords from sops
    systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];

    accounts = lib.mkIf (!config.swarselsystems.isPublic) {
      email = {
        maildirBasePath = "Mail";
        accounts = {
          leon = {
            primary = true;
            address = leonMail;
            userName = leonMail;
            realName = fullName;
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

          swarsel = {
            address = swarselMail;
            userName = "8227dc594dd515ce232eda1471cb9a19";
            realName = fullName;
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

          nautilus = {
            primary = false;
            address = nautilusMail;
            userName = nautilusMail;
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

          mrswarsel = {
            primary = false;
            address = mrswarselMail;
            userName = mrswarselMail;
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
  };
}
