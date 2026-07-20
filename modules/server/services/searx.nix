{
  flake.modules.nixos.searx =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "searx";
          port = 3002;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;

      inherit (config.swarselsystems) sopsFile;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "searx" ];
        topology.self.services.searxng.info = "https://${serviceDomain}";
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "OK";
            path = "/healthz";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets.searx-secret = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };

          templates."searx-env" = {
            content = ''
              SEARXNG_SECRET="${config.sops.placeholder.searx-secret}"
            '';
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
        };
        users.persistentIds.searx = confLib.mkIds 950;
        services.${serviceName} = {
          enable = true;
          environmentFile = config.sops.templates.searx-env.path;
          redisCreateLocally = true;
          settings = {

            default_doi_resolver = "sci-hub.se";
            doi_resolvers = {
              "doai.io" = "https://dissem.in/";
              "doi.org" = "https://doi.org/";
              "oadoi.org" = "https://oadoi.org/";
              "sci-hub.ru" = "https://sci-hub.ru/";
              "sci-hub.se" = "https://sci-hub.se/";
              "sci-hub.st" = "https://sci-hub.st/";
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
            engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {
              "aol images".disabled = true;
              "brave".disabled = true;
              "brave.images".disabled = true;
              "deviantart".disabled = true;
              "duckduckgo images".disabled = true;
              "google images".disabled = true;
              "karmasearch".disabled = true;
              "karmasearch images".disabled = true;
              "karmasearch videos".disabled = true;
              "pexels".disabled = true;
              "qwant images".disabled = true;
              "startpage".disabled = true;
              "startpage images".disabled = true;
              "unsplash".disabled = true;
            };
            faviconsSettings.favicons = {
              cache = {
                BLOB_MAX_BYTES = 40960;
                HOLD_TIME = 5184000;
                LIMIT_TOTAL_BYTES = 2147483648;
                MAINTENANCE_MODE = "auto";
                MAINTENANCE_PERIOD = 600;
                db_url = "/run/searx/faviconcache.db";
              };
              cfg_schema = 1;
              proxy.max_age = 5184000;
            };
            general = {
              contact_url = false;
              debug = false;
              donation_url = false;
              enable_metrics = true;
              instance_name = "SwarselSearX";
              privacypolicy_url = false;
            };
            # hostname_replace = {
            #   "pinterest\.com" = false;
            # };
            hostnames = {
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
              low_priority = [
                "(.*\.)?medium\.com$"
                "(.*\.)?quora\.com$"
              ];
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
              replace = {
                "(.*\.)?redd\.it$" = "old.reddit.com";
                "(.*\.)?reddit\.com$" = "old.reddit.com";
                "(.*\.)?youtu\.be$" = globals.services.invidious.domain;
                "(.*\.)?youtube\.com$" = globals.services.invidious.domain;
              };
            };
            search = {
              autocomplete = "google"; # "dbpedia", "duckduckgo", "google", "startpage", "swisscows", "qwant", "wikipedia" - leave blank to turn it off by default
              autocomplete_min = 3;
              default_lang = "en";
              favicon_resolver = "google";
              formats = [
                "html"
                "json"
                "rss"
              ];
              safe_search = 0; # 0 = None, 1 = Moderate, 2 = Strict
            };
            server = {
              base_url = "https://${globals.services.${serviceName}.domain}";
              bind_address = "0.0.0.0";
              image_proxy = true;
              limiter = false;
              port = servicePort;
              public_instance = false;
            };
            ui = {
              center_alignment = true;
              default_locale = "en";
              default_theme = "simple";
              infinite_scroll = false;
              query_in_title = true;
              search_on_category_select = true;
              static_use_hash = true;
              theme_args.simple_style = "auto";
            };

          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = "/var/lib/redis-${serviceName}";
            group = serviceGroup;
            mode = "0700";
            user = serviceUser;
          }
        ];
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              oauth2 = true;
              oauth2Groups = [ "searx_access" ];
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                oauth2 = true;
                oauth2Groups = [ "searx_access" ];
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };

    }

  ;
}
