{ pkgs, ... }: {
  android-integration = {
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    xdg-open.enable = true;
  };

  environment = {
    etcBackupExtension = ".bak";
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
    motd = null;
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
      nixfmt
      nvd
    ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "23.05";
}
