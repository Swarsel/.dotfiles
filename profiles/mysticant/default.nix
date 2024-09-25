{ pkgs, ... }: {
  environment = {
    packages = with pkgs; [
      vim
      git
      openssh
      toybox
      dig
      man
      gnupg
    ];

    etcBackupExtension = ".bak";
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
    motd = null;
  };

  home-manager.config = {

    imports = [
      ../common/home/ssh.nix
    ];
    services.ssh-agent.enable = true;

  };

  android-integration = {
    termux-open.enable = true;
    termux-xdg-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
  };

  # Backup etc files instead of failing to activate generation if a file already exists in /etc

  # Read the changelog before changing this value
  system.stateVersion = "23.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
