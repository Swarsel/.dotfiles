{
  root,
  inputs,
  lib,
  pkgs,
  arch,
  minimal,
  ...
}:
let
  mainUser = "demo";
in
{

  imports = [
    ./hardware-configuration.nix
    inputs.self.modules.nixos.disk-single-root
  ]
  ++ lib.optionals (!minimal) [
    inputs.self.modules.nixos.profile-public
  ]
  ++ lib.optionals (!minimal) (
    builtins.attrValues (
      lib.getAttrs [
        "niri"
        "noctalia"
      ] inputs.self.modules.nixos
    )
  );

  swarselsystems = {
    inherit mainUser;
    info = "~SwarselSystems~ demo host";
    isBtrfs = false;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isPublic = true;
    isSecureBoot = false;
    isSwap = true;
    rootDisk = "/dev/vda";
    swapSize = "4G";
    wallpaper = root "files/wallpaper/landscape/lenovowp.png";
  };

  topology.self.interfaces."demo host" = { };

  services = {
    printing.drivers = lib.mkIf (arch != "x86_64-linux") (lib.mkForce [ ]);
    qemuGuest.enable = true;
  };

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = lib.mkForce true;
    };
  };

  environment = {
    systemPackages = [ pkgs.yubikey-manager ];
    variables.WLR_RENDERER_ALLOW_SOFTWARE = 1;
  };

  hardware.graphics.enable32Bit = lib.mkIf (arch != "x86_64-linux") (lib.mkForce false);

  networking = {
    firewall.enable = true;
    hostName = "hotel";
  };

  nixpkgs.overlays = lib.mkAfter [
    (_: prev: {
      niri-unstable = prev.niri.overrideAttrs { inherit (prev.niri-unstable) patches; };
    })
  ];

}
