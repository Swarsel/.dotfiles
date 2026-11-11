{
  flake.modules.nixOnDroid = {
    packages = { pkgs, ... }: {
      environment.packages = with pkgs; [
        age
        bzip2
        cpio
        croc
        curl
        diffutils
        dig
        file
        gawk
        gnugrep
        gnupatch
        gnupg
        gnused
        gzip
        iproute2
        iputils
        just
        ncdu
        netcat-openbsd
        openssh
        openssl
        procps
        rsync
        time
        tree
        wget
        which
        xz
        yq-go
        zstd
      ];
    };
    settings =
      {
        inputs,
        lib,
        pkgs,
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
        };
        home-manager = {
          config = {
            swarselsystems.isPublic = true;
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
        user.shell = "${pkgs.zsh}/bin/zsh";
      };
    swarsel-droid = { pkgs, configName, ... }: {
      environment.packages = [ pkgs.swarsel-droid ];
      home-manager.config.home.sessionVariables.DROID_PROFILE = "droid-${configName}";
    };
  };
}
