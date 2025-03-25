{ pkgs, ... }:
{
  programs.ssh.startAgent = false;

  services.pcscd.enable = false;

  hardware.gpgSmartcards.enable = true;

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  # systemd.services.shutdownSopsGpg = {
  #   path = [ pkgs.gnupg ];
  #   script = ''
  #     gpgconf --homedir /var/lib/sops --kill gpg-agent
  #   '';
  #   wantedBy = [ "multi-user.target" ];
  # };

}
