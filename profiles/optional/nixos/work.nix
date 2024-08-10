{ pkgs, ... }:
{
  # boot.initrd.luks.yubikeySupport = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "swarsel" ];
  };

  environment.systemPackages = with pkgs; [
  ];


}
