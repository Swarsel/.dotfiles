{ lib, config, pkgs, ... }:
{
  options.swarselmodules.optional.virtualbox = lib.mkEnableOption "optional VBox settings";
  config = lib.mkIf config.swarselmodules.optional.virtualbox {
    # specialisation = {
    #   VBox.configuration = {
    virtualisation.virtualbox = {
      host = {
        enable = true;
        enableKvm = true;
        addNetworkInterface = lib.mkIf config.virtualisation.virtualbox.host.enableKvm false;
        package = pkgs.stable.virtualbox;
        enableExtensionPack = true;
      };
      # leaving this here for future notice. setting guest.enable = true will make 'restarting sysinit-reactivation.target' take till timeout on nixos-rebuild switch
      guest = {
        enable = false;
      };
    };
    # run an older kernel to provide compatibility with windows vm
    # boot = {
    #   kernelPackages = lib.mkForce pkgs.stable24_05.linuxPackages;
    #   # kernelParams = [
    #   #   "amd_iommu=on"
    #   # ];
    # };


    # fixes the issue of running together with QEMU
    # NOTE: once you start a QEMU VM (use kvm) VirtualBox will fail to start VMs
    # boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];
    #   };
    # };
  };

}
