{ self, config, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.microvm.nixosModules.microvm
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-minecraft.nixosModules.minecraft-servers
    inputs.nix-topology.nixosModules.default
    inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
    inputs.simple-nixos-mailserver.nixosModules.default
    inputs.sops.nixosModules.sops
    inputs.stylix.nixosModules.stylix
    inputs.swarsel-nix.nixosModules.default
    inputs.nixos-nftables-firewall.nixosModules.default
    inputs.pia.nixosModules.default

    (inputs.nixos-extra-modules + "/modules/interface-naming.nix")

    "${self}/modules/shared/meta.nix"
  ];

  config = {
    _module.args.dns = inputs.dns;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
    # NOTE: this is needed, we dont import sevrer network module for microvms
    globals.hosts.${config.node.name}.isHome = true;

    systemd.network.networks."10-vlan-services" = {
      dhcpV6Config = {
        WithoutRA = "solicit";
        # duid-en is nice in principle, but I already have MAC info anyways for reservations
        DUIDType = "link-layer";
      };
      # networkConfig = {
      #   IPv6PrivacyExtensions = "no";
      #   IPv6AcceptRA = false;
      # };
      ipv6AcceptRAConfig = {
        DHCPv6Client = "always";
      };
    };

    # microvm = {
    #   mount the writeable overlay so that we can use nix shells inside the microvm
    #   volumes = [
    #     {
    #       image = "/tmp/nix-store-overlay-${config.networking.hostName}.img";
    #       autoCreate = true;
    #       mountPoint = config.microvm.writableStoreOverlay;
    #       size = 1024;
    #     }
    #   ];
    # };
  };
}
