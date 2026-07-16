{
  globals = {
    root.hashedPassword = "$6$Hkbhj1DujcKvZP9t$hQEyYT11m/4/UjR6kq8NqINQk3PD5cKTvuyWTz5SstW2IbLDB/rgPs59MrVTbMzEPhimRp90HrxVbDvNG16Ny0";

    general = {
      homeProxy = "shim";
      homeWebProxy = "shim";
    };

    domains.main = "swarsel.internal";

    services.alloy.extraConfig.otlpGrpcPort = 4317;

    networks.home-lan.vlans.services = {
      id = 10;
      cidrv4 = "192.168.110.0/24";
      cidrv6 = "fd00:5a4d:10::/64";
    };
  };
}
