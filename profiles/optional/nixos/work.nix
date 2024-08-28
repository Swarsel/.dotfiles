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


}
