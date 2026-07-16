{
  flake.modules.nixos.networkdevices = { pkgs, confLib, ... }: {
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
          ];
        };
      };
      # enable scanners over network
      hardware.sane = {
        enable = true;
        extraBackends = [ pkgs.sane-airscan ];
      };
    };
  };
}
