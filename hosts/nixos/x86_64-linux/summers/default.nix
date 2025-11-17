{ inputs, lib, config, minimal, nodes, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  swarselsystems = {
    info = "ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
    withMicroVMs = false;
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
  };

  swarselmodules = {
    optional = {
      microvmHost = true;
    };
    server = {
      diskEncryption = lib.mkForce false; # TODO: disable
      nfs = false;
      nginx = false;
      kavita = false;
      restic = false;
      jellyfin = false;
      navidrome = false;
      spotifyd = false;
      mpd = false;
      postgresql = false;
      matrix = false;
      nextcloud = false;
      immich = false;
      paperless = false;
      transmission = false;
      syncthing = false;
      grafana = false;
      emacs = false;
      freshrss = false;
      jenkins = false;
      kanidm = false;
      firefly-iii = false;
      koillection = false;
      radicale = false;
      atuin = false;
      forgejo = false;
      ankisync = false;
      homebox = false;
      opkssh = false;
      garage = false;
    };
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
