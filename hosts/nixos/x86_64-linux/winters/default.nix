{ self, lib, minimal, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ];

  topology.self.interfaces."eth1" = { };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hosts = {
    ${globals.networks.home-lan.hosts.hintbooth.ipv4} = [ "server.hintbooth.${globals.domains.main}" ];
    ${globals.networks.home-lan.hosts.hintbooth.ipv6} = [ "server.hintbooth.${globals.domains.main}" ];
  };

  swarselsystems = {
    info = "ASRock J4105-ITX, 32GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = false;
    isSecureBoot = false;
    isCrypted = false;
    isBtrfs = false;
    isLinux = true;
    isNixos = true;
    proxyHost = "twothreetunnel";
    server = {
      wireguard.interfaces = {
        wgProxy = {
          isClient = true;
          serverName = "twothreetunnel";
        };
        wgHome = {
          isClient = true;
          serverName = "hintbooth";
        };
      };
    };
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    diskEncryption = lib.mkForce false;
  };

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" "enp3s0" ];

}
