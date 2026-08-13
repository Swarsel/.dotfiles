{
  flake.modules.nixos.networkdevices =
    {
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      printerAddress = globals.networks.home-lan.vlans.devices.hosts.dell-C2665dnf-F49D60.ipv4;
    in
    {
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
            publish = {
              enable = true;
              addresses = true;
              userServices = true;
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
        environment.etc."sane.d/airscan.conf".text = ''
          [devices]
          "Dell C2665dnf" = http://${printerAddress}/ws, wsd
        '';
        # enable scanners over network
        hardware = {
          printers.ensurePrinters = [
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
          sane = {
            enable = true;
            extraBackends = [ pkgs.sane-airscan ];
          };
        };
      };
    };
}
