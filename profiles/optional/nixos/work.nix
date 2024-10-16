{ pkgs, ... }:
{
  # boot.initrd.luks.yubikeySupport = true;
  programs.browserpass.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "swarsel" ];
  };
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [
    # (python39.withPackages (ps: with ps; [
    # cryptography
    # ]))
    #   docker
    python39
    qemu
    packer
    gnumake
    libisoburn
    govc
  ];

  services.openssh = {
    enable = true;
    extraConfig = ''
      '';
  };

  services.syncthing = {
    settings = {
      "winters" = {
        id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
      };
      folders = {
        "Documents" = {
          path = "/home/swarsel/Documents";
          devices = [ "magicant" "winters" ];
          id = "hgr3d-pfu3w";
        };
      };
    };
  };

  specialisation = {
    cgroup_v1.configuration = {
      boot.kernelParams = [
        "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
        "systemd.unified_cgroup_hierarchy=0"
      ];
    };
  };


}
