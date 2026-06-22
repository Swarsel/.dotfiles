{
  flake.modules.nixos.users =
    {
      pkgs,
      config,
      lib,
      globals,
      minimal,
      ...
    }:
    {
      config = {
        sops.secrets.main-user-hashed-pw = lib.mkIf (!config.swarselsystems.isPublic) {
          neededForUsers = true;
        };

        users = {
          mutableUsers = lib.mkIf (!minimal) false;
          users = {
            root = {
              inherit (globals.root) hashedPassword;
              # shell = pkgs.zsh;
            };
            "${config.swarselsystems.mainUser}" = {
              isNormalUser = true;
              uid = 1000;
              autoSubUidGidRange = false;
              subUidRanges = [
                {
                  count = 65534;
                  startUid = 100001;
                }
              ];
              subGidRanges = [
                {
                  count = 999;
                  startGid = 1001;
                }
              ];
              description = config.repo.secrets.common.fullName or "User";
              password = lib.mkIf (minimal || config.swarselsystems.isPublic) "setup";
              hashedPasswordFile = lib.mkIf (
                !minimal && !config.swarselsystems.isPublic
              ) config.sops.secrets.main-user-hashed-pw.path;
              extraGroups = [
                "wheel"
              ]
              ++ lib.optionals (!minimal && !config.swarselsystems.isMicroVM) [
                "networkmanager"
                "input"
                "syncthing"
                "docker"
                "lp"
                "audio"
                "video"
                "vboxusers"
                "builder"
                "libvirtd"
                "scanner"
              ];
              packages = with pkgs; [ ];
            };
          };
        };
      };
    };
}
