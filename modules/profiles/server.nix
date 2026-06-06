{
  flake.modules.nixos = {
    profile-localserver = { self, ... }: {
      imports = [
        # common modules
        self.modules.nixos.settings
        self.modules.nixos.lanzaboote
        self.modules.generic.pii
        self.modules.nixos.xserver
        self.modules.nixos.time
        self.modules.nixos.users
        self.modules.nixos.impermanence
        self.modules.nixos.sops
        self.modules.nixos.boot
        # server modules
        self.modules.nixos.btrfs
        self.modules.nixos.nftables-rules
        self.modules.nixos.server-settings
        self.modules.nixos.disk-encrypt
        self.modules.nixos.ssh
        self.modules.nixos.server-network
        self.modules.nixos.server-packages
        self.modules.nixos.attic-setup
        self.modules.nixos.dns-hostrecord
        # self.modules.nixos.oauth2-proxy
        self.modules.nixos.node-roles
        self.modules.nixos.alloy
        self.modules.nixos.blackbox
      ];
    };

    profile-microvm = { self, ... }: {
      imports = [
        # common modules
        self.modules.nixos.settings
        self.modules.generic.pii
        self.modules.nixos.xserver
        self.modules.nixos.time
        self.modules.nixos.users
        self.modules.nixos.impermanence
        self.modules.nixos.sops
        # server modules
        self.modules.nixos.btrfs
        self.modules.nixos.nftables-rules
        self.modules.nixos.server-settings
        self.modules.nixos.ssh
        self.modules.nixos.server-packages
        self.modules.nixos.wireguard
        self.modules.nixos.dns-home
        self.modules.nixos.opkssh
        # self.modules.nixos.oauth2-proxy
        self.modules.nixos.node-roles
        self.modules.nixos.alloy
        self.modules.nixos.blackbox
      ];

      config.swarselsystems = {
        isLinux = true;
      };
    };

    profile-router = { self, ... }: {
      imports = [
        self.modules.nixos.nftables-rules
        self.modules.nixos.router
        self.modules.nixos.kea
      ];
    };
  };
}
