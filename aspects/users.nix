{ den, ... }:
let
  hostContext = { host, ... }: {
    nixos = { minimal, lib, config, ... }: {
      users.users.swarsel = {
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
        description = "Leon S";
        password = lib.mkIf (minimal || host.isPublic) "setup";
        hashedPasswordFile = lib.mkIf (!minimal && !host.isPublic) config.sops.secrets.main-user-hashed-pw.path;
        extraGroups = lib.optionals (!minimal && !host.isMicroVM) [ "input" "syncthing" "docker" "lp" "audio" "video" "vboxusers" "libvirtd" "scanner" ];
      };
    };
  };

in
{

  den = {
    aspects.swarsel = {
      includes = [
        hostContext
        (den.provides.sops { class = "nixos"; name = "main-user-hashed-pw"; args = { neededForUsers = true; }; })
        den.provides.primary-user
        (den.provides.user-shell "zsh")
      ];
    };
    aspects.root = { globals, ... }: {
      nixos = {
        users.users.root = globals.root.hashedPassword;
      };
    };
  };
}
