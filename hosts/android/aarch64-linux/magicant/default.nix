{
  self,
  inputs,
  lib,
  pkgs,
  configName,
  globals,
  ...
}:
{
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
      age
      bottom
      croc
      curl
      deadnix
      dig
      droid-switch
      fd
      file
      git
      gnupg
      gnutar
      iproute2
      iputils
      jq
      just
      less
      man
      ncdu
      nix-output-monitor
      nix-tree
      nixfmt
      nvd
      openssh
      openssl
      ripgrep
      rsync
      sops
      ssh-to-age
      statix
      tree
      unzip
      vim
      wget
      yq-go
    ];
  };

  home-manager = {
    config = {
      imports = builtins.attrValues (
        lib.getAttrs [
          "eza"
          "git"
          "nix-index"
          "nix-your-shell"
          "starship"
          "zsh"
        ] self.modules.homeManager
      );
      swarselsystems.isPublic = true;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          belchsfactory = {
            HostName = globals.hosts.belchsfactory.wanAddress4;
            ProxyJump = "liliputsteps";
            StrictHostKeyChecking = "accept-new";
            User = "root";
          };
          liliputsteps = {
            HostName = globals.hosts.liliputsteps.wanAddress4;
            StrictHostKeyChecking = "accept-new";
            User = "jump";
          };
        };
      };
      home.sessionVariables.DROID_PROFILE = "droid-${configName}";
      systemd.user.tmpfiles.rules = lib.mkForce [ ];
    };
    backupFileExtension = "hm-bak";
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  system.stateVersion = "23.05";

  user = {
    gid = 10418;
    shell = "${pkgs.zsh}/bin/zsh";
    uid = 10418;
  };
}
