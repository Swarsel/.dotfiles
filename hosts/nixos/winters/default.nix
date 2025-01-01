{ self, inputs, outputs, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = [
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix

    "${profilesPath}/nixos/optional/autologin.nix"
    "${profilesPath}/nixos/server"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = [
        "${profilesPath}/home/server"
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }

  ] ++ (builtins.attrValues outputs.nixosModules);

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "winters";
    hostId = "b7778a4a";
    firewall.enable = true;
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
  };


  swarselsystems = {
    hasBluetooth = false;
    hasFingerprint = false;
    isImpermanence = false;
    isBtrfs = false;
    isLinux = true;
    flakePath = "/home/swarsel/.dotfiles";
    server = {
      enable = true;
      kavita = true;
      navidrome = true;
      jellyfin = true;
      spotifyd = true;
      mpd = false;
      matrix = true;
      nextcloud = true;
      immich = true;
      paperless = true;
      transmission = true;
      syncthing = true;
      monitoring = true;
      freshrss = true;
    };
  };

}
