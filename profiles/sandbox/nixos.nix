{ config, lib, pkgs, inputs, ... }:

{

  
  imports =
    [
      ./hardware-configuration.nix
    ];
  

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    listenAddresses = [{
      port = 22;
      addr = "0.0.0.0";
    }];
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../secrets/keys/authorized_keys
  ];


  environment.shellAliases = {
    nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  networking.hostName = "sandbox"; # Define your hostname.
  networking.enableIPv6 = false;

  users.users.swarsel = {
    isNormalUser = true;
    description = "Leon S";
    extraGroups = [ "networkmanager" "wheel" "lp"];
    packages = with pkgs; [];
  };

  system.stateVersion = "23.05"; # Did you read the comment?

  environment.systemPackages = with pkgs; [
  ];


}
