{ self, lib, pkgs, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "immich"; port = 3001; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy idmServer homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) sopsFile;

  kanidmDomain = globals.services.kanidm.domain;
  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  imports = [
    "${self}/modules/nixos/server/postgresql.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "immich" ];

    sops.secrets = {
      kanidm-immich = { sopsFile = kanidmSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      immich-smtp-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };


    users = {
      persistentIds = {
        immich = confLib.mkIds 989;
        redis-immich = confLib.mkIds 977;
      };
      users.${serviceUser} = {
        extraGroups = [ "video" "render" "users" ];
      };
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    # networking.firewall.allowedTCPPorts = [ servicePort ];
    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/api/server/ping"; expectedBodyRegex = ''"res":\s*"pong"''; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }
        { directory = "/var/cache/${serviceName}"; user = serviceUser; group = serviceGroup; }
        { directory = "/var/lib/redis-${serviceName}"; user = "redis-${serviceUser}"; group = "redis-${serviceGroup}"; }
      ];
    };

    services.${serviceName} = {
      enable = true;
      package = pkgs.immich;
      host = "0.0.0.0";
      port = servicePort;
      # openFirewall = true;
      mediaLocation = "/storage/Pictures/${serviceName}"; # dataDir
      environment = {
        IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://localhost:3003";
      };
      settings = {
        backup.database = {
          cronExpression = "0 02 * * *";
          enabled = true;
          keepLastAmount = 14;
        };
        ffmpeg = {
          accel = "disabled";
          accelDecode = false;
          acceptedAudioCodecs = [ "aac" "mp3" "opus" ];
          acceptedContainers = [ "mov" "ogg" "webm" ];
          acceptedVideoCodecs = [ "h264" ];
          bframes = -1;
          cqMode = "auto";
          crf = 23;
          gopSize = 0;
          maxBitrate = "0";
          preferredHwDevice = "auto";
          preset = "ultrafast";
          refs = 0;
          targetAudioCodec = "aac";
          targetResolution = "720";
          targetVideoCodec = "h264";
          temporalAQ = false;
          threads = 0;
          tonemap = "hable";
          transcode = "required";
          twoPass = false;
        };
        image = {
          colorspace = "p3";
          extractEmbedded = false;
          fullsize = {
            enabled = false;
            format = "jpeg";
            progressive = false;
            quality = 80;
          };
          preview = {
            format = "jpeg";
            progressive = false;
            quality = 80;
            size = 1440;
          };
          thumbnail = {
            format = "webp";
            progressive = false;
            quality = 80;
            size = 250;
          };
        };
        job = {
          backgroundTask.concurrency = 5;
          editor.concurrency = 2;
          faceDetection.concurrency = 2;
          library.concurrency = 5;
          metadataExtraction.concurrency = 5;
          migration.concurrency = 5;
          notifications.concurrency = 5;
          ocr.concurrency = 1;
          search.concurrency = 5;
          sidecar.concurrency = 5;
          smartSearch.concurrency = 2;
          thumbnailGeneration.concurrency = 3;
          videoConversion.concurrency = 1;
          workflow.concurrency = 5;
        };
        library = {
          scan = {
            cronExpression = "0 0 * * *";
            enabled = true;
          };
          watch.enabled = false;
        };
        logging = {
          enabled = true;
          level = "debug";
        };
        machineLearning = {
          availabilityChecks = {
            enabled = true;
            interval = 30000;
            timeout = 2000;
          };
          clip = {
            enabled = true;
            modelName = "ViT-B-32__openai";
          };
          duplicateDetection = {
            enabled = true;
            maxDistance = 0.01;
          };
          enabled = true;
          facialRecognition = {
            enabled = true;
            maxDistance = 0.5;
            minFaces = 3;
            minScore = 0.7;
            modelName = "buffalo_l";
          };
          ocr = {
            enabled = true;
            maxResolution = 736;
            minDetectionScore = 0.5;
            minRecognitionScore = 0.8;
            modelName = "PP-OCRv5_mobile";
          };
          urls = [ "http://127.0.0.1:3003" ];
        };
        map = {
          darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
          enabled = true;
          lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
        };
        metadata.faces.import = false;
        newVersionCheck.enabled = false;
        nightlyTasks = {
          clusterNewFaces = true;
          databaseCleanup = true;
          generateMemories = true;
          missingThumbnails = true;
          startTime = "00:00";
          syncQuotaUsage = true;
        };
        notifications.smtp = {
          enabled = true;
          from = "Immich <notification@${globals.domains.main}>";
          replyTo = "notification@${globals.domains.main}";
          transport = {
            host = globals.services.mailserver.domain;
            ignoreCert = false;
            password._secret = config.sops.secrets.immich-smtp-pw.path;
            port = 587;
            secure = false;
            username = "notification@${globals.domains.main}";
          };
        };
        oauth = {
          autoLaunch = false;
          autoRegister = true;
          buttonText = "Login with Kanidm";
          clientId = serviceName;
          clientSecret._secret = config.sops.secrets.kanidm-immich.path;
          defaultStorageQuota = null;
          enabled = true;
          issuerUrl = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
          mobileOverrideEnabled = true;
          mobileRedirectUri = "https://${serviceDomain}/api/oauth/mobile-redirect";
          profileSigningAlgorithm = "none";
          roleClaim = "immich_role";
          scope = "openid email profile";
          signingAlgorithm = "RS256";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "0";
          timeout = 30000;
          tokenEndpointAuthMethod = "client_secret_post";
        };
        passwordLogin.enabled = true;
        reverseGeocoding.enabled = true;
        server = {
          externalDomain = "";
          loginPageMessage = "";
          publicUsers = true;
        };
        storageTemplate = {
          enabled = false;
          hashVerificationEnabled = true;
          template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
        };
        templates.email = {
          albumInviteTemplate = "";
          albumUpdateTemplate = "";
          welcomeTemplate = "";
        };
        theme.customCss = "";
        trash = {
          days = 30;
          enabled = true;
        };
        user.deleteDelay = 7;
      };
    };

    nodes =
      let
        extraConfigLoc = ''
          proxy_http_version 1.1;
          proxy_set_header   Upgrade    $http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_redirect     off;

          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout       600s;
        '';
      in
      {
        ${idmServer} = lib.recursiveUpdate
          (confLib.mkKanidmOidcSystem {
            inherit serviceName serviceDomain kanidmSopsFile;
            originUrl = [
              "https://${serviceDomain}/auth/login"
              "https://${serviceDomain}/user-settings"
              "app.immich:///oauth-callback"
              "https://${serviceDomain}/api/oauth/mobile-redirect"
            ];
          })
          {
            services.kanidm.provision.systems.oauth2.immich.enableLegacyCrypto = true;
          };
        ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; };
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
      };

  };
}
