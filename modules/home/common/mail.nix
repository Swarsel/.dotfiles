{ lib, config, nixosConfig ? config, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1 address2 address2-name address3 address3-name address4 address4-user address4-host;
  inherit (nixosConfig.repo.secrets.common) fullName;
  inherit (config.swarselsystems) xdgDir;
in
{
  options.swarselmodules.mail = lib.mkEnableOption "mail settings";
  config = lib.mkIf config.swarselmodules.mail {

    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic && !config.swarselsystems.isNixos) {
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

    programs.thunderbird = {
      enable = true;
      profiles.default = {
        isDefault = true;
        withExternalGnupg = true;
        settings = {
          "mail.identity.default.archive_enabled" = true;
          "mail.identity.default.archive_keep_folder_structure" = true;
          "mail.identity.default.compose_html" = false;
          "mail.identity.default.protectSubject" = true;
          "mail.identity.default.reply_on_top" = 1;
          "mail.identity.default.sig_on_reply" = false;
          "mail.identity.default.sig_bottom" = false;

          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
        };
      };

      settings = {
        "mail.server.default.allow_utf8_accept" = true;
        "mail.server.default.max_articles" = 1000;
        "mail.server.default.check_all_folders_for_new" = true;
        "mail.show_headers" = 1;
        "mail.identity.default.auto_quote" = true;
        "mail.identity.default.attachPgpKey" = true;
        "mailnews.default_sort_order" = 2;
        "mailnews.default_sort_type" = 18;
        "mailnews.default_view_flags" = 0;
        "mailnews.sort_threads_by_root" = true;
        "mailnews.headers.showMessageId" = true;
        "mailnews.headers.showOrganization" = true;
        "mailnews.headers.showReferences" = true;
        "mailnews.headers.showUserAgent" = true;
        "mail.imap.expunge_after_delete" = true;
        "mail.server.default.delete_model" = 2;
        "mail.warn_on_delete_from_trash" = false;
        "mail.warn_on_shift_delete" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.rejected" = true;
        "toolkit.telemetry.prompted" = 2;
        "app.update.auto" = false;
        "privacy.donottrackheader.enabled" = true;
      };
    };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      "x-scheme-handler/mid" = [ "thunderbird.desktop" ];
      "message/rfc822" = [ "thunderbird.desktop" ];
    };

    accounts = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      email =
        let
          defaultSettings = {
            imap = {
              host = "imap.gmail.com";
              port = 993;
              tls.enable = true; # SSL/TLS
            };
            smtp = {
              host = "smtp.gmail.com";
              port = 465;
              tls.enable = true; # SSL/TLS
            };
            thunderbird = {
              enable = true;
              profiles = [ "default" ];
            };
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
        in
        {
          maildirBasePath = "Mail";
          accounts = {
            swarsel = {
              address = address4;
              userName = address4-user;
              realName = fullName;
              passwordCommand = "cat ${nixosConfig.sops.secrets.address4-token.path}";
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

            leon = lib.recursiveUpdate
              {
                primary = true;
                address = address1;
                userName = address1;
                realName = fullName;
                passwordCommand = "cat ${nixosConfig.sops.secrets.address1-token.path}";
                gpg = {
                  key = "0x76FD3810215AE097";
                  signByDefault = true;
                };
              }
              defaultSettings;

            nautilus = lib.recursiveUpdate
              {
                primary = false;
                address = address2;
                userName = address2;
                realName = address2-name;
                passwordCommand = "cat ${nixosConfig.sops.secrets.address2-token.path}";
              }
              defaultSettings;

            mrswarsel = lib.recursiveUpdate
              {
                primary = false;
                address = address3;
                userName = address3;
                realName = address3-name;
                passwordCommand = "cat ${nixosConfig.sops.secrets.address3-token.path}";
              }
              defaultSettings;

          };
        };
    };
  };
}
