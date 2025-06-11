{ lib, config, nixosConfig, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1 address2 add2Name address3 add3Name address4;
  inherit (nixosConfig.repo.secrets.common) fullName;
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
            address = address1;
            userName = address1;
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
            address = address4;
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
            address = address2;
            userName = address2;
            realName = add2Name;
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
            address = address3;
            userName = address3;
            realName = add3Name;
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
