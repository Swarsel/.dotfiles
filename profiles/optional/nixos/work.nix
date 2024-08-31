{ pkgs, ... }:
{
  # boot.initrd.luks.yubikeySupport = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "swarsel" ];
  };
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [
    python39
    docker
  ];

  specialisation = {
    cgroup_v1.configuration = {
      boot.kernelParams = [
        "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
        "systemd.unified_cgroup_hierarchy=0"
      ];
    };
  };
}
