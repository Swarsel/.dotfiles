{ lib, config, ... }:
let
  serviceName = "router";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    systemd.network = {
      wait-online.anyInterface = true;
      networks = {
        "30-lan0" = {
          matchConfig.Name = "lan0";
          linkConfig.RequiredForOnline = "enslaved";
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
        "30-lan1" = {
          matchConfig.Name = "lan1";
          linkConfig.RequiredForOnline = "enslaved";
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
        "30-lan2" = {
          matchConfig.Name = "lan2";
          linkConfig.RequiredForOnline = "enslaved";
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
        "30-lan3" = {
          matchConfig.Name = "lan3";
          linkConfig.RequiredForOnline = "enslaved";
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
        "10-wan" = {
          matchConfig.Name = "wan";
          networkConfig = {
            # start a DHCP Client for IPv4 Addressing/Routing
            DHCP = "ipv4";
            DNSOverTLS = true;
            DNSSEC = true;
            IPv6PrivacyExtensions = false;
            IPForward = true;
          };
          # make routing on this interface a dependency for network-online.target
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };
  };
}
