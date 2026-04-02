{ lib, config, confLib, ... }:
let
  inherit (lib)
    concatLists
    flip
    mapAttrsToList
    mkDefault
    mkIf
    mkOption
    types
    ;

  cfg = config.users.persistentIds;
in
{
  options = {
    swarselmodules.server.ids = lib.mkEnableOption "enable persistent ids on server";
    users = {
      persistentIds = mkOption {
        default = { };
        description = ''
          Maps a user or group name to its expected uid/gid values. If a user/group is
          used on the system without specifying a uid/gid, this module will assign the
          corresponding ids defined here, or show an error if the definition is missing.
        '';
        type = types.attrsOf (
          types.submodule {
            options = {
              uid = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "The uid to assign if it is missing in `users.users.<name>`.";
              };
              gid = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "The gid to assign if it is missing in `users.groups.<name>`.";
              };
            };
          }
        );
      };

      users = mkOption {
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              config.uid =
                let
                  persistentUid = cfg.${name}.uid or null;
                in
                mkIf (persistentUid != null) (mkDefault persistentUid);
            }
          )
        );
      };

      groups = mkOption {
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              config.gid =
                let
                  persistentGid = cfg.${name}.gid or null;
                in
                mkIf (persistentGid != null) (mkDefault persistentGid);
            }
          )
        );
      };
    };
  };
  config = lib.mkIf config.swarselmodules.server.ids {
    assertions =
      concatLists
        (
          flip mapAttrsToList config.users.users (
            name: user: [
              {
                assertion = user.uid != null;
                message = "non-persistent uid detected for '${name}', please assign one via `users.persistentIds`";
              }
              {
                assertion = !user.autoSubUidGidRange;
                message = "non-persistent subUids/subGids detected for: ${name}";
              }
            ]
          )
        )
      ++ flip mapAttrsToList config.users.groups (
        name: group: {
          assertion = group.gid != null;
          message = "non-persistent gid detected for '${name}', please assign one via `users.persistentIds`";
        }
      );
    users.persistentIds = {
      systemd-coredump = confLib.mkIds 998;
      systemd-oom = confLib.mkIds 997;
      polkituser = confLib.mkIds 973;
      nscd = confLib.mkIds 972;
    };
  };
}
