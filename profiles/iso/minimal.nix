{ lib, pkgs, ... }:
{

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };

  boot = {
    # initrd.systemd.enable = true;
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce [ "brtfs" "vfat" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 5;
        consoleMode = lib.mkDefault "max";
      };
    };
  };

  services = {
    qemuGuest.enable = true;
    openssh = {
      enable = true;
      ports = lib.mkDefault [ 22 ];
      settings.PermitRootLogin = "yes";
      authorizedKeysFiles = lib.mkForce [
        "/etc/ssh/authorized_keys.d/%u"
      ];
    };
  };

  security.pam = {
    sshAgentAuth.enable = true;
    services = {
      sudo.u2fAuth = true;
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    rsync
    ssh-to-age
    sops
    vim
    just
  ];

  programs = {
    git.enable = true;
    zsh.enable = lib.mkDefault true;
  };

  fileSystems."/boot".options = [ "umask=0077" ];

  networking.networkmanager.enable = true;


}
