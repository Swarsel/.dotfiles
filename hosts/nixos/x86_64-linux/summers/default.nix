{ self, inputs, lib, config, minimal, nodes, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/microvm-host.nix"
  ];

  topology.self = {
    interfaces = {
      "eth1" = { };
      "eth2" = { };
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  node.lockFromBootstrapping = lib.mkForce false;

  swarselsystems = {
    info = "ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/ata-TS128GMTS430S_H537280456";
    withMicroVMs = false;
    server.localNetwork = "lan";
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
  };

  microvm.vms =
    let
      mkMicrovm = guestName: {
        ${guestName} = {
          backend = "microvm";
          autostart = true;
          modules = [
            ./guests/${guestName}.nix
            {
              node.secretsDir = ./secrets/${guestName};
            }
          ];
          microvm = {
            system = "x86_64-linux";
            # baseMac = config.repo.secrets.local.networking.interfaces.lan.mac;
            # interfaces.vlan-services = { };
          };
          specialArgs = {
            inherit (config) nodes globals;
            inherit lib;
            inherit inputs minimal;
          };
        };
      };
    in
    lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
      { }
      // mkMicrovm "guest1"
    );

}
