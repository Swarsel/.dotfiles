{ config, pkgs, ... }:

{

  services = {
    getty.autologinUser = "swarsel";
    greetd.settings.initial_session.user = "swarsel";
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # kernelPackages = pkgs.linuxPackages_latest;
  };

  sops.age.sshKeyPaths = [ "${config.users.users.swarsel.home}/.ssh/sops" ];

  networking = {
    hostName = "fourside"; # Define your hostname.
    nftables.enable = true;
    enableIPv6 = false;
    firewall.checkReversePath = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 4380 27036 14242 34197 51820 ]; # 34197: factorio; 4380 27036 14242: barotrauma; 51820: wireguard
      allowedTCPPorts = [ ]; # 34197: factorio; 4380 27036 14242: barotrauma; 51820: wireguard
      allowedTCPPortRanges = [
        { from = 27015; to = 27030; } # barotrauma
        { from = 27036; to = 27037; } # barotrauma
      ];
      allowedUDPPortRanges = [
        { from = 27000; to = 27031; } # barotrauma
        { from = 58962; to = 58964; } # barotrauma
      ];
    };
  };

  virtualisation.virtualbox = {
    host = {
      enable = true;
      enableExtensionPack = true;
    };
    # leaving this here for future notice. setting guest.enable = true will make 'restarting sysinit-reactivation.target' take till timeout on nixos-rebuild switch
    guest = {
      enable = false;
    };
  };

  stylix.image = ../../wallpaper/lenovowp.png;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
      ];
    };
    bluetooth.enable = true;
    trackpoint = {
      enable = true;
      device = "TPPS/2 Elan TrackPoint";
    };
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

  # Configure keymap in X11 (only used for login)

  services.thinkfan = {
    enable = false;
  };
  services.power-profiles-daemon.enable = true;
  services.fprintd.enable = true;
  services.fwupd.enable = true;

  services.nswitch-rcm = {
    enable = true;
    package = pkgs.fetchurl {
      url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/1.3.2/fusee.bin";
      hash = "sha256-5AXzNsny45SPLIrvWJA9/JlOCal5l6Y++Cm+RtlJppI=";
    };
  };


  environment.systemPackages = with pkgs; [
    # gog games installing
    heroic
    # minecraft
    temurin-bin-17
    (prismlauncher.override {
      glfw = pkgs.glfw-wayland-minecraft;
    })
  ];

  system.stateVersion = "23.05";


}
