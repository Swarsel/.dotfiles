# adapted from https://github.com/oddlama/nix-config/blob/main/modules/distributed-config.nix
{
  flake.modules.nixos.nodes =
    {
      config,
      lib,
      nodes,
      ...
    }:
    let
      nodeName = config.node.name;
      mkForwardedOption =
        path:
        lib.mkOption {
          default._type = "__distributed_config_empty";
          description = ''
            Anything specified here will be forwarded to `${lib.concatStringsSep "." path}`
            on the given node. Forwarding happens as-is to the raw values,
            so validity can only be checked on the receiving node.
          '';
          type = lib.mkOptionType {
            merge =
              _loc: defs:
              builtins.filter (x: builtins.isAttrs x -> ((x._type or "") != "__distributed_config_empty")) (
                map (x: x.value) defs
              );
            name = "Same type that the receiving option `${lib.concatStringsSep "." path}` normally accepts.";
          };
        };

      splitPath = path: lib.splitString "." path;
      expandOptions = basePath: optionNames: map (option: basePath ++ splitPath option) optionNames;

      forwardedOptions = [
        (splitPath "boot.kernel.sysctl")
        (splitPath "networking.nftables.chains.postrouting")
        (splitPath "services.kanidm.provision.groups")
        (splitPath "services.kanidm.provision.systems.oauth2")
        (splitPath "sops.secrets")
        (splitPath "topology.self.services")
      ]
      ++ expandOptions [ "environment" ] [ "persistence" "etc" ]
      ++ expandOptions (splitPath "networking.nftables.firewall") [
        "zones"
        "rules"
      ]
      ++ expandOptions (splitPath "services.firezone.gateway") [
        "enable"
        "name"
        "apiUrl"
        "tokenFile"
        "package"
        "logLevel"
      ]
      ++ expandOptions (splitPath "services.nginx") [
        "upstreams"
        "virtualHosts"
        "streamConfig"
      ]
      ++ expandOptions (splitPath "services.grafana") [
        "settings"
        "provision.datasources.settings.datasources"
        "provision.alerting.rules.settings.groups"
      ];

      attrsForEachOption =
        f:
        lib.foldl' (
          acc: path: lib.recursiveUpdate acc (lib.setAttrByPath path (f path))
        ) { } forwardedOptions;
    in
    {
      options.nodes = lib.mkOption {
        default = { };
        description = "Options forwarded to the given node.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = attrsForEachOption mkForwardedOption;
          }
        );
      };
      config =
        let
          getConfig =
            path: otherNode:
            let
              cfg = nodes.${otherNode}.config.nodes.${nodeName} or null;
            in
            lib.optionals (cfg != null) (lib.getAttrFromPath path cfg);
          mergeConfigFromOthers = path: lib.mkMerge (lib.concatMap (getConfig path) (lib.attrNames nodes));
        in
        attrsForEachOption mergeConfigFromOthers;
    };
}
