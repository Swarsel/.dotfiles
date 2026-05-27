{ config, pkgs, lib, confLib, ... }:
let
  inherit (config.swarselsystems) homeDir;
  inherit (confLib.getConfig.repo.secrets.local.mail) allMailAddresses;
  inherit (confLib.getConfig.repo.secrets.local.work) mailAddress;
in
{
  config = {
    systemd.user.sessionVariables = lib.optionalAttrs (!config.swarselsystems.isPublic) {
      SWARSEL_MAIL_ALL = lib.mkForce allMailAddresses;
      SWARSEL_MAIL_WORK = lib.mkForce mailAddress;
    };

    accounts.email.accounts.work =
      let
        inherit (confLib.getConfig.repo.secrets.local.work) mailName;
      in
      {
        primary = false;
        address = mailAddress;
        userName = mailAddress;
        realName = mailName;
        passwordCommand = "pizauth show work";
        imap = {
          host = "outlook.office365.com";
          port = 993;
          tls.enable = true;
        };
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
            "mail.smtpserver.smtp_${id}.authMethod" = 10;
            "mail.server.server_${id}.authMethod" = 10;
          };
        };
        msmtp = {
          enable = true;
          extraConfig = {
            auth = "xoauth2";
            host = "outlook.office365.com";
            protocol = "smtp";
            port = "587";
            tls = "on";
            tls_starttls = "on";
            from = "${mailAddress}";
            user = "${mailAddress}";
            passwordeval = "pizauth show work";
          };
        };
        mu.enable = true;
        mbsync = {
          enable = true;
          expunge = "both";
          patterns = [ "INBOX" ];
          extraConfig = {
            account = {
              AuthMechs = "XOAUTH2";
            };
          };
        };
      };

    services.pizauth = {
      enable = true;
      extraConfig = ''
          auth_notify_cmd = "if [[ \"$(notify-send -A \"Open $PIZAUTH_ACCOUNT\" -t 30000 'pizauth authorisation')\" == \"0\" ]]; then open \"$PIZAUTH_URL\"; fi";
        error_notify_cmd = "notify-send -t 90000 \"pizauth error for $PIZAUTH_ACCOUNT\" \"$PIZAUTH_MSG\"";
        token_event_cmd = "pizauth dump > ${homeDir}/.pizauth.state";
      '';
      accounts = {
        work = {
          authUri = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
          tokenUri = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
          clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
          clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";
          scopes = [
            "https://outlook.office365.com/IMAP.AccessAsUser.All"
            "https://outlook.office365.com/SMTP.Send"
            "offline_access"
          ];
          loginHint = mailAddress;
        };
      };
    };

    systemd.user.services.pizauth.Service.ExecStartPost = [
      "${pkgs.toybox}/bin/sleep 1"
      "//bin/sh -c '${lib.getExe pkgs.pizauth} restore < ${homeDir}/.pizauth.state'"
    ];
  };
}
