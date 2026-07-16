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
      firefox-syncserver.domain = "firefox-sync.example.org";
      invidious.domain = "invidious.example.org";
      kanidm.domain = "kanidm.example.org";
      matrix.domain = "matrix.example.org";
      searx.domain = "searx.example.org";
      syncthing-shim.extraConfig.devices = { };
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
