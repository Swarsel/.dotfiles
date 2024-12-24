{ self, inputs, outputs, config, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = [
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix

    "${profilesPath}/optional/nixos/autologin.nix"
    "${profilesPath}/server/nixos"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = [
        "${profilesPath}/server/home"
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }

  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

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
