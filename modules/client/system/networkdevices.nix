{
  flake.modules.nixos.networkdevices =
    {
      self,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      printerAddress = globals.networks.home-lan.vlans.devices.hosts.dell-C2665dnf-F49D60.ipv4;
    in
    {
      imports = [ self.modules.nixos.network-scanner ];
      config = {
        users.persistentIds = {
          avahi = confLib.mkIds 978;
          lpadmin = confLib.mkIds 954;
        };
        services = {
          avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
            settings.publish = {
              disable-publishing = false;
              disable-user-service-publishing = false;
              publish-addresses = true;
            };
          };
          # enable discovery and usage of network devices (esp. printers)
          printing = {
            enable = true;
            browsedConf = ''
              BrowseDNSSDSubTypes _cups,_print
              BrowseLocalProtocols all
              BrowseRemoteProtocols all
              CreateIPPPrinterQueues All
              BrowseProtocols all
            '';
            drivers = [
              pkgs.gutenprint
              pkgs.gutenprintBin
              pkgs.foomatic-db-ppds
            ];
          };
        };
        hardware.printers.ensurePrinters = [
          {
            deviceUri = "ipp://${printerAddress}:631/ipp";
            model = "foomatic-db-ppds/Generic-PostScript_Printer-Postscript.ppd.gz";
            name = "Dell_C2665dnf";
            ppdOptions = {
              Duplex = "DuplexNoTumble";
              PageSize = "A4";
            };
          }
        ];
      };
    };
}
