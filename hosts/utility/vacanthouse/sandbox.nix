{
  self,
  lib,
  globals,
  ...
}:
{
  imports = [
    self.modules.nixos.homebox
  ];

  config = {
    sandbox.tlsDomains = [ globals.services.homebox.domain ];

    networking.firewall.allowedTCPPorts = [ 7745 ];

    sops.secrets.kanidm-homebox = {
      owner = lib.mkForce "kanidm";
      group = lib.mkForce "kanidm";
      mode = lib.mkForce "0440";
    };

    services.kanidm.provision.groups."homebox.access".members = [ "sandbox" ];

    systemd.services.homebox = {
      wants = [ "kanidm.service" ];
      after = [
        "kanidm.service"
        "nginx.service"
      ];
    };

    virtualisation.vmVariant.virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 7745;
        guest.port = 7745;
      }
    ];
  };
}
