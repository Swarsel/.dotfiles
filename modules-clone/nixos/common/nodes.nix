# adapted from https://github.com/oddlama/nix-config/blob/main/modules/distributed-config.nix
{ config, lib, nodes, ... }:
let
  nodeName = config.node.name;
  mkForwardedOption =
    path:
    lib.mkOption {
      type = lib.mkOptionType {
        name = "Same type that the receiving option `${lib.concatStringsSep "." path}` normally accepts.";
        merge =
          _loc: defs:
          builtins.filter (x: builtins.isAttrs x -> ((x._type or "") != "__distributed_config_empty")) (
            map (x: x.value) defs
          );
      };
      default = {
        _type = "__distributed_config_empty";
      };
      description = ''
        Anything specified here will be forwarded to `${lib.concatStringsSep "." path}`
        on the given node. Forwarding happens as-is to the raw values,
        so validity can only be checked on the receiving node.
      '';
    };

  expandOptions = basePath: optionNames: map (option: basePath ++ [ option ]) optionNames;
  splitPath = path: lib.splitString "." path;

  forwardedOptions = [
    (splitPath "boot.kernel.sysctl")
    (splitPath "networking.nftables.chains.postrouting")
    (splitPath "services.kanidm.provision.groups")
    (splitPath "services.kanidm.provision.systems.oauth2")
    (splitPath "sops.secrets")
    (splitPath "swarselsystems.server.dns")
    (splitPath "topology.self.services")
    (splitPath "environment.persistence")
  ]
  ++ expandOptions (splitPath "networking.nftables.firewall") [ "zones" "rules" ]
  ++ expandOptions (splitPath "services.firezone.gateway") [ "enable" "name" "apiUrl" "tokenFile" "package" "logLevel" ]
  ++ expandOptions (splitPath "services.nginx") [ "upstreams" "virtualHosts" ]
  ;

  attrsForEachOption =
    f: lib.foldl' (acc: path: lib.recursiveUpdate acc (lib.setAttrByPath path (f path))) { } forwardedOptions;
in
{
  options.nodes = lib.mkOption {
    description = "Options forwarded to the given node.";
    default = { };
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
}
