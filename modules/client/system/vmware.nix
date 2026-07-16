{
  flake.modules.nixos.vmware = {
    config = {
      virtualisation = {
        vmware = {
          guest.enable = true;
          host.enable = true;
        };
      };
    };
  };
}
