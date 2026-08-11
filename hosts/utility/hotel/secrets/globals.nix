{
  globals = {
    services = {
      alloy.extraConfig = {
        clients = { };
        otlpGrpcPort = 4317;
      };
      ankisync.domain = "ankisync.example.org";
      attic.domain = "attic.example.org";
      atuin.domain = "atuin.example.org";
      buildbot.domain = "buildbot.example.org";
      copyparty.domain = "copyparty.example.org";
      firefly-iii.domain = "firefly.example.org";
      firefox-syncserver.domain = "firefox-sync.example.org";
      forgejo.domain = "forgejo.example.org";
      freshrss.domain = "freshrss.example.org";
      grafana.domain = "grafana.example.org";
      homebox.domain = "homebox.example.org";
      immich.domain = "immich.example.org";
      invidious.domain = "invidious.example.org";
      jellyfin.domain = "jellyfin.example.org";
      kanidm.domain = "kanidm.example.org";
      kavita.domain = "kavita.example.org";
      koillection.domain = "koillection.example.org";
      matrix.domain = "matrix.example.org";
      mealie.domain = "mealie.example.org";
      microbin.domain = "microbin.example.org";
      navidrome.domain = "navidrome.example.org";
      nextcloud.domain = "nextcloud.example.org";
      paperless.domain = "paperless.example.org";
      searx.domain = "searx.example.org";
      shlink.domain = "shlink.example.org";
      shopservatory.domain = "shopservatory.example.org";
      slink.domain = "slink.example.org";
      syncthing-moonside.domain = "syncthing-moonside.example.org";
      syncthing-shim.extraConfig.devices = { };
      syncthing-summers-storage.domain = "syncthing-summers-storage.example.org";
      transmission.domain = "transmission.example.org";
    };
    general = {
      homeProxy = "shim";
      homeSyncthingServer = "shim";
      homeWebProxy = "shim";
      idmServer = "shim";
      monitoringServer = "shim";
      routerServer = "shim";
      webProxy = "shim";
    };
    root.hashedPassword = "$6$Hkbhj1DujcKvZP9t$hQEyYT11m/4/UjR6kq8NqINQk3PD5cKTvuyWTz5SstW2IbLDB/rgPs59MrVTbMzEPhimRp90HrxVbDvNG16Ny0"; # setup
  };
}
