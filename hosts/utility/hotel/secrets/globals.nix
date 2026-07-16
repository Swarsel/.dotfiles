{
  globals = {
    root.hashedPassword = "$6$Hkbhj1DujcKvZP9t$hQEyYT11m/4/UjR6kq8NqINQk3PD5cKTvuyWTz5SstW2IbLDB/rgPs59MrVTbMzEPhimRp90HrxVbDvNG16Ny0"; # setup

    general = {
      homeProxy = "shim";
      webProxy = "shim";
      routerServer = "shim";
      homeWebProxy = "shim";
      idmServer = "shim";
      monitoringServer = "shim";
      homeSyncthingServer = "shim";
    };

    services = {
      alloy.extraConfig = {
        clients = { };
        otlpGrpcPort = 4317;
      };
      syncthing-shim.extraConfig.devices = { };
      ankisync.domain = "ankisync.example.org";
      attic.domain = "attic.example.org";
      atuin.domain = "atuin.example.org";
      firefox-syncserver.domain = "firefox-sync.example.org";
      invidious.domain = "invidious.example.org";
      kanidm.domain = "kanidm.example.org";
      matrix.domain = "matrix.example.org";
      searx.domain = "searx.example.org";
    };
  };
}
