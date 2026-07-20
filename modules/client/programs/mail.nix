{
  flake.modules.homeManager.mail =
    {
      config,
      lib,
      confLib,
      globals,
      nixosConfig ? null,
      ...
    }:
    let
      inherit (confLib.getConfig.repo.secrets.common.mail)
        address1
        address2
        address2-name
        address3
        address3-name
        address4
        ;
      inherit (confLib.getConfig.repo.secrets.common) fullName;
    in
    {
      config = {
        swarselsystems = {
          enabledHomeModules = [ "mail" ];
          homeSopsSecrets = {
            address1-token = { };
            address2-token = { };
            address3-token = { };
            address4-token = { };
          };
        };
        services.mbsync.enable = true;
        programs = {
          mbsync.enable = true;
          msmtp.enable = true;
          mu.enable = true;
        };
        programs.thunderbird = {
          enable = true;
          profiles.default = {
            isDefault = true;
            settings = {
              "gfx.webrender.all" = true;
              "gfx.webrender.enabled" = true;
              "mail.identity.default.archive_enabled" = true;
              "mail.identity.default.archive_keep_folder_structure" = true;
              "mail.identity.default.compose_html" = false;
              "mail.identity.default.protectSubject" = true;
              "mail.identity.default.reply_on_top" = 1;
              "mail.identity.default.sig_bottom" = false;
              "mail.identity.default.sig_on_reply" = false;
            };
            withExternalGnupg = true;
          };

          settings = {
            "app.update.auto" = false;
            "mail.identity.default.attachPgpKey" = true;
            "mail.identity.default.auto_quote" = true;
            "mail.imap.expunge_after_delete" = true;
            "mail.server.default.allow_utf8_accept" = true;
            "mail.server.default.check_all_folders_for_new" = true;
            "mail.server.default.delete_model" = 2;
            "mail.server.default.max_articles" = 1000;
            "mail.show_headers" = 1;
            "mail.warn_on_delete_from_trash" = false;
            "mail.warn_on_shift_delete" = false;
            "mailnews.default_sort_order" = 2;
            "mailnews.default_sort_type" = 18;
            "mailnews.default_view_flags" = 0;
            "mailnews.headers.showMessageId" = true;
            "mailnews.headers.showOrganization" = true;
            "mailnews.headers.showReferences" = true;
            "mailnews.headers.showUserAgent" = true;
            "mailnews.sort_threads_by_root" = true;
            "privacy.donottrackheader.enabled" = true;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.prompted" = 2;
            "toolkit.telemetry.rejected" = true;
          };
        };
        accounts = lib.mkIf ((nixosConfig != null) && !config.swarselsystems.isPublic) {
          email =
            let
              defaultSettings = {
                imap = {
                  host = "imap.gmail.com";
                  port = 993;
                  tls.enable = true; # SSL/TLS
                };
                mbsync = {
                  enable = true;
                  create = "maildir";
                  expunge = "both";
                  extraConfig = {
                    account = {
                      AuthMechs = "LOGIN";
                      PipelineDepth = 1;
                      Timeout = 120;
                    };
                    channel.Sync = "All";
                  };
                  patterns = [
                    "*"
                    "![Gmail]*"
                    "[Gmail]/Sent Mail"
                    "[Gmail]/Starred"
                    "[Gmail]/All Mail"
                  ];
                };
                msmtp.enable = true;
                mu.enable = true;
                smtp = {
                  host = "smtp.gmail.com";
                  port = 465;
                  tls.enable = true; # SSL/TLS
                };
                thunderbird = {
                  enable = true;
                  profiles = [ "default" ];
                };
              };
            in
            {
              accounts = {
                leon = lib.recursiveUpdate {
                  address = address1;
                  gpg = {
                    key = "0x76FD3810215AE097";
                    signByDefault = true;
                  };
                  passwordCommand = "cat ${confLib.getConfig.sops.secrets.address1-token.path}";
                  primary = true;
                  realName = fullName;
                  userName = address1;
                } defaultSettings;
                mrswarsel = lib.recursiveUpdate {
                  address = address3;
                  passwordCommand = "cat ${confLib.getConfig.sops.secrets.address3-token.path}";
                  primary = false;
                  realName = address3-name;
                  userName = address3;
                } defaultSettings;
                nautilus = lib.recursiveUpdate {
                  address = address2;
                  passwordCommand = "cat ${confLib.getConfig.sops.secrets.address2-token.path}";
                  primary = false;
                  realName = address2-name;
                  userName = address2;
                } defaultSettings;
                swarsel = {
                  address = address4;
                  imap = {
                    host = globals.services.mailserver.domain;
                    port = 993;
                    tls.enable = true; # SSL/TLS
                  };
                  mbsync = {
                    enable = true;
                    create = "maildir";
                    expunge = "both";
                    extraConfig = {
                      account = {
                        AuthMechs = "LOGIN";
                        PipelineDepth = 1;
                        Timeout = 120;
                      };
                      channel.Sync = "All";
                    };
                    patterns = [ "*" ];
                  };
                  msmtp.enable = true;
                  mu.enable = true;
                  passwordCommand = "cat ${confLib.getConfig.sops.secrets.address4-token.path}";
                  realName = fullName;
                  smtp = {
                    host = globals.services.mailserver.domain;
                    port = 465;
                    tls.enable = true; # SSL/TLS
                  };
                  thunderbird = {
                    enable = true;
                    profiles = [ "default" ];
                  };
                  userName = address4;
                };

              };
              maildirBasePath = "Mail";
            };
        };
        xdg.mimeApps.defaultApplications = {
          "message/rfc822" = [ "thunderbird.desktop" ];
          "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
          "x-scheme-handler/mid" = [ "thunderbird.desktop" ];
        };
        # this is needed so that mbsync can use the passwords from sops
        systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
      };
    };
}
