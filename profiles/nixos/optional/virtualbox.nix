{ lib, pkgs, ... }:
{

  specialisation = {
    VBox.configuration = {
      virtualisation.virtualbox = {
        host = {
          enable = true;
          enableExtensionPack = true;
        };
        # leaving this here for future notice. setting guest.enable = true will make 'restarting sysinit-reactivation.target' take till timeout on nixos-rebuild switch
        guest = {
          enable = false;
        };
      };
      # run an older kernel to provide compatibility with windows vm
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    };
  };

}