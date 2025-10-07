{ lib, config, ... }:
{
  options.swarselmodules.optional.microvmGuest = lib.mkEnableOption "optional microvmGuest settings";
  # imports = [
  #   inputs.microvm.nixosModules.microvm
  #   "${self}/profiles/nixos"
  #   "${self}/modules/nixos"
  # ];
  config = lib.mkIf config.swarselmodules.optional.microvmGuest
    {
      # imports = [
      #   inputs.microvm.nixosModules.microvm

      #   "${self}/profiles/nixos"
      #   "${self}/modules/nixos"
      # ];

      boot.kernelParams = [ "systemd.hostname=${config.networking.hostName}" ];

      node.name = config;
      documentation.enable = lib.mkForce false;

      microvm = {
        guest.enable = lib.mkForce true;
        hypervisor = lib.mkDefault "qemu";
        mem = lib.mkDefault 1024 * 4;
        vcpu = lib.mkDefault 4;
        optimize.enable = false;
        writableStoreOverlay = "/nix/.rw-store";

        # interfaces = flip lib.mapAttrsToList guestCfg.microvm.interfaces (
        #   _: { mac, hostLink, ...}:
        #   {
        #     type = "macvtap";
        #     id = "vm-${replaceStrings [ ":" ] [ "" ] mac}";
        #     inherit mac;
        #     macvtap = {
        #       link = hostLink;
        #       mode = "bridge";
        #     };
        #   }
        # );
        shares =
          [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "ro-store";
              proto = "virtiofs";
            }
          ];
      };
      # systemd.network.networks = lib.flip lib.concatMapAttrs guestCfg.microvm.interfaces (
      #   name:
      #   { mac, ... }:
      #   {
      #     "10-${name}".matchConfig = mkForce {
      #       MACAddress = mac;
      #     };
      #   }
      # );

    };
}
