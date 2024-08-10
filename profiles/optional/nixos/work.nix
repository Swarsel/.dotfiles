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

  # xdg.portal = {
  #   enable = true;
  #   config = {
  #     common = {
  #       default = "wlr";
  #     };
  #   };
  #   wlr.enable = true;
  #   wlr.settings.screencast = {
  #     output_name = "eDP-2";
  #     chooser_type = "simple";
  #     chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
  #   };
  # };


  # services.dbus.enable = true;

}
