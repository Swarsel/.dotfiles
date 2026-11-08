{
  flake.modules.nixos.users =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      minimal,
      ...
    }:
    let
      mainUserEnabled = config.users.users.${config.swarselsystems.mainUser}.enable;
    in
    {
      config = {
        sops.secrets = {
          main-user-hashed-pw = lib.mkIf (mainUserEnabled && !config.swarselsystems.isPublic) {
            neededForUsers = true;
            rekey.keyPrefix = confLib.static.sharedSecrets.common;
          };
          root-hashed-pw = lib.mkIf (!minimal && !config.swarselsystems.isPublic) {
            neededForUsers = true;
            rekey.keyPrefix = confLib.static.sharedSecrets.common;
          };
        };
        users = {
          users = {
            "${config.swarselsystems.mainUser}" = {
              enable = lib.mkDefault (
                minimal
                || config.swarselsystems.isPublic
                || (config.home-manager.users or { }) ? ${config.swarselsystems.mainUser}
              );
              autoSubUidGidRange = false;
              description = config.repo.secrets.common.fullName or "User";
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
              hashedPasswordFile = lib.mkIf (
                mainUserEnabled && !minimal && !config.swarselsystems.isPublic
              ) config.sops.secrets.main-user-hashed-pw.path;
              isNormalUser = true;
              packages = with pkgs; [ ];
              password = lib.mkIf (minimal || config.swarselsystems.isPublic) "setup";
              subGidRanges = [
                {
                  count = 65534;
                  startGid = 100001;
                }
              ];
              subUidRanges = [
                {
                  count = 65534;
                  startUid = 100001;
                }
              ];
              uid = lib.mkIf mainUserEnabled 1000;
            };
            root = {
              hashedPassword = lib.mkIf config.swarselsystems.isPublic globals.root.hashedPassword;
              hashedPasswordFile = lib.mkIf (
                !minimal && !config.swarselsystems.isPublic
              ) config.sops.secrets.root-hashed-pw.path;
              # shell = pkgs.zsh;
            };
          };
          mutableUsers = lib.mkIf (!minimal) false;
        };
        security.pam.services.su.requireWheel = true;
      };
    };
}
