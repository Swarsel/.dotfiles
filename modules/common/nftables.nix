{
  flake-file.inputs.nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";

  flake.modules.nixos = {
    nftables =
      { inputs, ... }:
      {
        imports = [ inputs.nixos-nftables-firewall.nixosModules.default ];
      };

    nftables-rules =
      {
        config,
        lib,
        globals,
        ...
      }:
      let
        inherit (globals.general) jumphost;
        restrictSsh = config.swarselsystems.isCloud && config.node.name != jumphost;
        sshSources = family: [
          globals.hosts.${jumphost}."wanAddress${family}"
          globals.networks.home-wan."cidrv${family}"
        ];
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "nftables" ];
          services.openssh.openFirewall = lib.mkIf restrictSsh false;
          networking.nftables = {
            firewall = {
              enable = true;
              localZoneName = "local";
              rules = {
                icmp-and-igmp = {
                  after = [
                    "ct"
                    "ssh"
                  ];
                  extraLines = [
                    "meta l4proto ipv6-icmp accept"
                    "meta l4proto icmp accept"
                    "ip protocol igmp accept"
                  ];
                  from = "all";
                  to = [ "local" ];
                };
                ssh = lib.mkIf restrictSsh {
                  allowedTCPPorts = config.services.openssh.ports;
                  from = [
                    "trusted-ssh"
                  ]
                  ++ lib.attrNames (
                    lib.filterAttrs (
                      name: zone: zone.parent == null && !zone.localZone && name != "untrusted"
                    ) config.networking.nftables.firewall.zones
                  );
                  to = [ "local" ];
                };
                untrusted-to-local = {
                  inherit (config.networking.firewall)
                    allowedTCPPortRanges
                    allowedTCPPorts
                    allowedUDPPortRanges
                    allowedUDPPorts
                    ;
                  from = [ "untrusted" ];
                  ignoreEmptyRule = true;
                  to = [ "local" ];
                };
              };
              snippets = {
                nnf-common.enable = false;
                nnf-conntrack.enable = true;
                nnf-dhcpv6.enable = true;
                nnf-drop.enable = true;
                nnf-loopback.enable = true;
                nnf-ssh.enable = !restrictSsh;
              };
              zones.trusted-ssh = lib.mkIf restrictSsh {
                ipv4Addresses = sshSources "4";
                ipv6Addresses = sshSources "6";
                parent = lib.mkIf (config.networking.nftables.firewall.zones ? untrusted) "untrusted";
              };
            };
            stopRuleset = lib.mkDefault ''
              table inet filter {
                chain input {
                  type filter hook input priority filter; policy drop;
                  ct state invalid drop
                  ct state {established, related} accept

                  iifname lo accept
                  meta l4proto ipv6-icmp accept
                  meta l4proto icmp accept
                  ip protocol igmp accept
                  tcp dport ${toString (lib.head config.services.openssh.ports)} accept
                }
                chain forward {
                  type filter hook forward priority filter; policy drop;
                }
                chain output {
                  type filter hook output priority filter; policy accept;
                }
              }
            '';
          };
        };
        key = "swarsel/nftables-rules";
      };
  };
}
