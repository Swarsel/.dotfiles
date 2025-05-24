{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.networkDevices = lib.mkEnableOption "network device config";
  config = lib.mkIf config.swarselsystems.modules.networkDevices {
    # enable scanners over network
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };

    # enable discovery and usage of network devices (esp. printers)
    services.printing = {
      enable = true;
      drivers = [
        pkgs.gutenprint
        pkgs.gutenprintBin
      ];
      browsedConf = ''
        BrowseDNSSDSubTypes _cups,_print
        BrowseLocalProtocols all
        BrowseRemoteProtocols all
        CreateIPPPrinterQueues All
        BrowseProtocols all
      '';
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
