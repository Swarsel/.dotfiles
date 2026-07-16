{
  globals = {
    services.alloy.extraConfig.otlpGrpcPort = 4317;
    domains.main = "swarsel.internal";
    general = {
      homeProxy = "shim";
      homeWebProxy = "shim";
    };
    networks.home-lan.vlans.services = {
      cidrv4 = "192.168.110.0/24";
      cidrv6 = "fd00:5a4d:10::/64";
      id = 10;
    };
    root.hashedPassword = "$6$Hkbhj1DujcKvZP9t$hQEyYT11m/4/UjR6kq8NqINQk3PD5cKTvuyWTz5SstW2IbLDB/rgPs59MrVTbMzEPhimRp90HrxVbDvNG16Ny0";
  };
}
