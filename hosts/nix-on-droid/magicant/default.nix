{ pkgs, ... }: {
  environment = {
    packages = with pkgs; [
      vim
      git
      openssh
      # toybox
      dig
      man
      gnupg
      curl
      deadnix
      statix
      nixpgks-fmt
      nvd
    ];

    etcBackupExtension = ".bak";
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
    motd = null;
  };


  android-integration = {
    termux-open.enable = true;
    xdg-open.enable = true;
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
