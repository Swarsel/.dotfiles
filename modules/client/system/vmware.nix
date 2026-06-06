{
  flake.modules.nixos.vmware = {
    config = {
      virtualisation.vmware.host.enable = true;
      virtualisation.vmware.guest.enable = true;
    };
  };
}
