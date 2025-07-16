{ lib, config, nixosConfig, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1 address2 address2-name address3 address3-name address4 address4-user address4-host;
  inherit (nixosConfig.repo.secrets.common) fullName;
  inherit (config.swarselsystems) xdgDir;
in
{
  options.swarselmodules.mail = lib.mkEnableOption "mail settings";
  config = lib.mkIf config.swarselmodules.mail {

    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
      address1-token = { path = "${xdgDir}/secrets/address1-token"; };
      address2-token = { path = "${xdgDir}/secrets/address2-token"; };
      address3-token = { path = "${xdgDir}/secrets/address3-token"; };
      address4-token = { path = "${xdgDir}/secrets/address4-token"; };
    };

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

    accounts = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      email = {
        maildirBasePath = "Mail";
        accounts = {
          leon = {
            primary = true;
            address = address1;
            userName = address1;
            realName = fullName;
            passwordCommand = "cat ${config.sops.secrets.address1-token.path}";
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
            userName = address4-user;
            realName = fullName;
            passwordCommand = "cat ${config.sops.secrets.address4-token.path}";
            smtp = {
              host = address4-host;
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
            realName = address2-name;
            passwordCommand = "cat ${config.sops.secrets.address2-token.path}";
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
            realName = address3-name;
            passwordCommand = "cat ${config.sops.secrets.address3-token.path}";
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
