{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "searx"; port = 3002; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied idmServer webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  inherit (config.swarselsystems) sopsFile;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "searx" ];

    sops = {
      secrets = {
        searx-secret = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };

      templates = {
        "searx-env" = {
          content = ''
            SEARXNG_SECRET="${config.sops.placeholder.searx-secret}"
          '';
          owner = serviceUser;
          group = serviceGroup;
          mode = "0440";
        };
      };
    };

    users.persistentIds = {
      searx = confLib.mkIds 950;
    };

    topology.self.services.searxng = {
      info = "https://${serviceDomain}";
    };

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/healthz";
        expectedBodyRegex = "OK";
        network = "local-${config.node.name}";
      };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    services.${serviceName} = {
      enable = true;
      redisCreateLocally = true;
      environmentFile = config.sops.templates.searx-env.path;
      settings = {

        general = {
          privacypolicy_url = false;
          enable_metrics = true;
          instance_name = "SwarselSearX";
          donation_url = false;
          contact_url = false;
          debug = false;
        };

        ui = {
          static_use_hash = true;
          default_locale = "en";
          query_in_title = true;
          infinite_scroll = false;
          center_alignment = true;
          default_theme = "simple";
          theme_args.simple_style = "auto";
          search_on_category_select = true;
        };

        doi_resolvers = {
          "oadoi.org" = "https://oadoi.org/";
          "doi.org" = "https://doi.org/";
          "doai.io" = "https://dissem.in/";
          "sci-hub.se" = "https://sci-hub.se/";
          "sci-hub.st" = "https://sci-hub.st/";
          "sci-hub.ru" = "https://sci-hub.ru/";
        };
        default_doi_resolver = "sci-hub.se";

        server = {
          port = servicePort;
          bind_address = "0.0.0.0";
          image_proxy = true;
          base_url = "https://${globals.services.${serviceName}.domain}";
          limiter = false;
          public_instance = false;
        };

        engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {
          "aol images".disabled = true;
          "brave".disabled = true;
          "brave.images".disabled = true;
          "deviantart".disabled = true;
          "duckduckgo images".disabled = true;
          "google images".disabled = true;
          "karmasearch images".disabled = true;
          "karmasearch videos".disabled = true;
          "karmasearch".disabled = true;
          "pexels".disabled = true;
          "qwant images".disabled = true;
          "startpage images".disabled = true;
          "startpage".disabled = true;
          "unsplash".disabled = true;
        };

        # hostname_replace = {
        #   "pinterest\.com" = false;
        # };
        hostnames = {
          replace = {
            "(.*\.)?redd\.it$" = "old.reddit.com";
            "(.*\.)?reddit\.com$" = "old.reddit.com";
            "(.*\.)?youtu\.be$" = globals.services.invidious.domain;
            "(.*\.)?youtube\.com$" = globals.services.invidious.domain;
          };
          remove = [
            "(.*\.)?answers\.microsoft\.com$"
            "(.*\.)?breitbart\.com$"
            "(.*\.)?dailymail\.co\.uk$"
            "(.*\.)?etsy\.com$"
            "(.*\.)?facebook\.com$"
            "(.*\.)?foxnews\.com$"
            "(.*\.)?geeksforgeeks\.org$"
            "(.*\.)?githubplus\.com$"
            "(.*\.)?instagram\.com$"
            "(.*\.)?linkedin\.com$"
            "(.*\.)?msn\.com$"
            "(.*\.)?nixos\.wiki$"
            "(.*\.)?pinterest\.ca$"
            "(.*\.)?pinterest\.co\.uk$"
            "(.*\.)?pinterest\.com$"
            "(.*\.)?pinterest\.com\.au$"
            "(.*\.)?pinterest\.de$"
            "(.*\.)?pinterest\.es$"
            "(.*\.)?pinterest\.fr$"
            "(.*\.)?play\.google\.com$"
            "(.*\.)?redditmedia\.com$"
            "(.*\.)?softonic\.com$"
            "(.*\.)?tiktok\.com$"
            "(.*\.)?twitter\.com$"
            "(.*\.)?w3schools\.com$"
            "(.*\.)?wikihow\.com$"
          ];
          low_priority = [
            "(.*\.)?medium\.com$"
            "(.*\.)?quora\.com$"
          ];
          high_priority = [
            "(.*\.)?arxiv\.org$"
            "(.*\.)?askubuntu\.com$"
            "(.*\.)?caniuse\.com$"
            "(.*\.)?codeberg\.org$"
            "(.*\.)?crates\.io$"
            "(.*\.)?crossref\.org$"
            "(.*\.)?dev\.mysql\.com$"
            "(.*\.)?devdocs\.io$"
            "(.*\.)?developer\.mozilla\.org$"
            "(.*\.)?discourse\.nixos\.org$"
            "(.*\.)?doc\.rust-lang\.org$"
            "(.*\.)?docker\.com$"
            "(.*\.)?docs\.ansible\.com$"
            "(.*\.)?docs\.docker\.com$"
            "(.*\.)?docs\.python\.org$"
            "(.*\.)?forums\.gentoo\.org$"
            "(.*\.)?freebsd\.org$"
            "(.*\.)?git-scm\.com$"
            "(.*\.)?github\.com$"
            "(.*\.)?gitlab\.com$"
            "(.*\.)?golang\.org$"
            "(.*\.)?hackerne\.ws$"
            "(.*\.)?helm\.sh$"
            "(.*\.)?hub\.docker\.com$"
            "(.*\.)?huggingface\.co$"
            "(.*\.)?ieeexplore\.ieee\.org$"
            "(.*\.)?kernel\.org$"
            "(.*\.)?kubernetes\.io$"
            "(.*\.)?letsencrypt\.org$"
            "(.*\.)?lobste\.rs$"
            "(.*\.)?mongodb\.com/docs$"
            "(.*\.)?news\.ycombinator\.com$"
            "(.*\.)?nginx\.org$"
            "(.*\.)?nixos\.org$"
            "(.*\.)?nodejs\.org$"
            "(.*\.)?npmjs\.com$"
            "(.*\.)?old\.reddit\.com$"
            "(.*\.)?openwrt\.org$"
            "(.*\.)?pkg\.go\.dev$"
            "(.*\.)?postgresql\.org$"
            "(.*\.)?pubmed\.ncbi\.nlm\.nih\.gov$"
            "(.*\.)?pypi\.org$"
            "(.*\.)?redd\.it$"
            "(.*\.)?reddit\.com$"
            "(.*\.)?scholar\.google\.com$"
            "(.*\.)?search\.nixos\.org$"
            "(.*\.)?semanticscholar\.org$"
            "(.*\.)?serverfault\.com$"
            "(.*\.)?specifications\.freedesktop\.org$"
            "(.*\.)?sqlite\.org$"
            "(.*\.)?stackexchange\.com$"
            "(.*\.)?stackoverflow\.com$"
            "(.*\.)?superuser\.com$V"
            "(.*\.)?terraform\.io$"
            "(.*\.)?tldp\.org$"
            "(.*\.)?w3\.org$"
            "(.*\.)?web\.dev$"
            "(.*\.)?wiki\.archlinux\.org$"
            "(.*\.)?wiki\.gentoo\.org$"
            "(.*\.)?wiki\.nixos\.org$"
            "(.*\.)?wikipedia\.org$"
          ];
        };

        enabled_plugins = [
          "Calculator"
          "Self information"
          "Hash plugin"
          "Hostname replace"
          "Open Access DOI rewrite"
          "Timezones plugin"
          "Tor check plugin"
          "Tracker URL remover"
          "Unit converter plugin"
        ];

        search = {
          safe_search = 0; # 0 = None, 1 = Moderate, 2 = Strict
          favicon_resolver = "google";
          formats = [
            "html"
            "json"
            "rss"
          ];
          autocomplete = "google"; # "dbpedia", "duckduckgo", "google", "startpage", "swisscows", "qwant", "wikipedia" - leave blank to turn it off by default
          autocomplete_min = 3;
          default_lang = "en";
        };

        faviconsSettings = {
          favicons = {
            cfg_schema = 1;
            cache = {
              db_url = "/run/searx/faviconcache.db";
              LIMIT_TOTAL_BYTES = 2147483648;
              HOLD_TIME = 5184000;
              BLOB_MAX_BYTES = 40960;
              MAINTENANCE_MODE = "auto";
              MAINTENANCE_PERIOD = 600;
            };

            proxy = {
              max_age = 5184000;
            };
          };
        };

      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = "/var/lib/redis-${serviceName}"; user = serviceUser; group = serviceGroup; mode = "0700"; }
    ];

    nodes = {
      ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; oauth2 = true; oauth2Groups = [ "searx_access" ]; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; oauth2 = true; oauth2Groups = [ "searx_access" ]; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };

}
