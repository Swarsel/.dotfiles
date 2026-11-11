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
        systemd.network.networks."10-vlan-services" = {
          dhcpV6Config = {
            # duid-en is nice in principle, but I already have MAC info anyways for reservations
            DUIDType = "link-layer";
            WithoutRA = "solicit";
          };
          ipv6AcceptRAConfig.DHCPv6Client = "always";
        };
      };
    };
}
