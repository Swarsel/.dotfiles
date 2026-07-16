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
    sops.secrets.kanidm-homebox = {
      group = lib.mkForce "kanidm";
      mode = lib.mkForce "0440";
      owner = lib.mkForce "kanidm";
    };
    services.kanidm.provision.groups."homebox.access".members = [ "sandbox" ];
    networking.firewall.allowedTCPPorts = [ 7745 ];
    sandbox.tlsDomains = [ globals.services.homebox.domain ];
    virtualisation.vmVariant.virtualisation.forwardPorts = [
      {
        from = "host";
        guest.port = 7745;
        host.port = 7745;
      }
    ];
    systemd.services.homebox = {
      after = [
        "kanidm.service"
        "nginx.service"
      ];
      wants = [ "kanidm.service" ];
    };
  };
}
