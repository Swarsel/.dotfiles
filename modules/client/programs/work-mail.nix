{
  flake.modules.homeManager.work-mail =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir;
      inherit (confLib.getConfig.repo.secrets.work) mailAddress;
    in
    {
      config = {
        services.pizauth = {
          enable = true;
          accounts.work = {
            authUri = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
            clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
            clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";
            loginHint = mailAddress;
            scopes = [
              "https://outlook.office365.com/IMAP.AccessAsUser.All"
              "https://outlook.office365.com/SMTP.Send"
              "offline_access"
            ];
            tokenUri = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
          };
          extraConfig = ''
              auth_notify_cmd = "if [[ \"$(notify-send -A \"Open $PIZAUTH_ACCOUNT\" -t 30000 'pizauth authorisation')\" == \"0\" ]]; then open \"$PIZAUTH_URL\"; fi";
            error_notify_cmd = "notify-send -t 90000 \"pizauth error for $PIZAUTH_ACCOUNT\" \"$PIZAUTH_MSG\"";
            token_event_cmd = "pizauth dump > ${homeDir}/.pizauth.state";
          '';
        };
        accounts.email.accounts.work =
          let
            inherit (confLib.getConfig.repo.secrets.work) mailName;
          in
          {
            address = mailAddress;
            imap = {
              host = "outlook.office365.com";
              port = 993;
              tls.enable = true;
            };
            mbsync = {
              enable = true;
              expunge = "both";
              extraConfig.account.AuthMechs = "XOAUTH2";
              patterns = [ "INBOX" ];
            };
            msmtp = {
              enable = true;
              extraConfig = {
                auth = "xoauth2";
                from = "${mailAddress}";
                host = "outlook.office365.com";
                passwordeval = "pizauth show work";
                port = "587";
                protocol = "smtp";
                tls = "on";
                tls_starttls = "on";
                user = "${mailAddress}";
              };
            };
            mu.enable = true;
            passwordCommand = "pizauth show work";
            primary = false;
            realName = mailName;
            smtp = {
              host = "outlook.office365.com";
              port = 587;
              tls = {
                enable = true;
                useStartTls = true;
              };
            };
            thunderbird = {
              enable = true;
              profiles = [ "default" ];
              settings = id: {
                "mail.server.server_${id}.authMethod" = 10;
                "mail.smtpserver.smtp_${id}.authMethod" = 10;
              };
            };
            userName = mailAddress;
          };
        systemd.user = {
          services.pizauth.Service.ExecStartPost = [
            "${pkgs.toybox}/bin/sleep 1"
            "//bin/sh -c '${lib.getExe pkgs.pizauth} restore < ${homeDir}/.pizauth.state'"
          ];
          sessionVariables = lib.optionalAttrs (!config.swarselsystems.isPublic) {
            SWARSEL_MAIL_ALL = lib.mkForce "${confLib.getConfig.repo.secrets.common.mail.allMailAddresses},${mailAddress}";
            SWARSEL_MAIL_WORK = lib.mkForce mailAddress;
          };
        };
      };
    };
}
