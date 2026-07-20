{
  flake.modules.nixos.microvm-guest =
    {
      self,
      inputs,
      config,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        inputs.microvm.nixosModules.microvm
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nix-minecraft.nixosModules.minecraft-servers
        inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
        inputs.simple-nixos-mailserver.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.swarsel-nix.nixosModules.default

        (inputs.nixos-extra-modules + "/modules/interface-naming.nix")

        self.modules.nixos.profile-base
      ];
      config = {
        # NOTE: this is needed, we dont import sevrer network module for microvms
        globals.hosts.${config.node.name}.isHome = true;
        _module.args.dns = inputs.dns;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        systemd = {
          services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
          network.networks."10-vlan-services" = {
            dhcpV6Config = {
              # duid-en is nice in principle, but I already have MAC info anyways for reservations
              DUIDType = "link-layer";
              WithoutRA = "solicit";
            };
            # networkConfig = {
            #   IPv6PrivacyExtensions = "no";
            #   IPv6AcceptRA = false;
            # };
            ipv6AcceptRAConfig.DHCPv6Client = "always";
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

  ;
}
