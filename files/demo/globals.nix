{
  globals = {
    root.hashedPassword = "$6$Hkbhj1DujcKvZP9t$hQEyYT11m/4/UjR6kq8NqINQk3PD5cKTvuyWTz5SstW2IbLDB/rgPs59MrVTbMzEPhimRp90HrxVbDvNG16Ny0"; # setup

    user = {
      name = "demo";
      work = "demo";
    };

    general = {
      internetVLANs = [ "home" ];
      homeProxy = "demo-homeproxy";
      routerServer = "demo-router";
      webProxy = "demo-webproxy";
      dnsServer = "demo-dns";
      homeDnsServer = "demo-homedns";
      homeWebProxy = "demo-homewebproxy";
      idmServer = "demo-idm";
      oauthServer = "demo-oauth";
      monitoringServer = "demo-monitoring";
      homeSyncthingServer = "demo-syncthing";
    };

    domains = {
      main = "example.org";
      externalDns = [ "9.9.9.9" ];
    };

    services = {
      alloy.extraConfig = {
        clients = { };
        otlpGrpcPort = 4317;
      };
      syncthing-demo-syncthing.extraConfig.devices = { };
      ankisync.domain = "ankisync.example.org";
      attic.domain = "attic.example.org";
      atuin.domain = "atuin.example.org";
      croc.domain = "croc.example.org";
      firefox-syncserver.domain = "firefox-sync.example.org";
      firezone.domain = "firezone.example.org";
      freshrss.domain = "freshrss.example.org";
      gotify.domain = "gotify.example.org";
      invidious.domain = "invidious.example.org";
      kanidm.domain = "kanidm.example.org";
      loki = {
        domain = "loki.example.org";
        extraConfig.host = "demo-monitoring";
      };
      mailserver.domain = "mail.example.org";
      matrix.domain = "matrix.example.org";
      mimir = {
        domain = "mimir.example.org";
        extraConfig.host = "demo-monitoring";
      };
      navidrome.domain = "navidrome.example.org";
      nextcloud.domain = "nextcloud.example.org";
      pyroscope = {
        domain = "pyroscope.example.org";
        extraConfig.host = "demo-monitoring";
      };
      radicale.domain = "radicale.example.org";
      roundcube.domain = "roundcube.example.org";
      searx.domain = "searx.example.org";
      tempo.domain = "tempo.example.org";
    };

    networks = { };

    hosts = {
      hotel = {
        defaultGateway4 = null;
        defaultGateway6 = null;
        wanAddress4 = null;
        wanAddress6 = null;
        isHome = false;
      };
    };
  };
}
