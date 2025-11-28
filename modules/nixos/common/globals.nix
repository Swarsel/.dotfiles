{ lib, options, ... }:
let
  inherit (lib)
    mkOption
    types
    ;

  networkOptions = netSubmod: {
    cidrv4 = mkOption {
      type = types.nullOr types.net.cidrv4;
      description = "The CIDRv4 of this network";
      default = null;
    };

    subnetMask4 = mkOption {
      type = types.nullOr types.net.ipv4;
      description = "The dotted decimal form of the subnet mask of this network";
      readOnly = true;
      default = lib.swarselsystems.cidrToSubnetMask netSubmod.config.cidrv4;
    };

    cidrv6 = mkOption {
      type = types.nullOr types.net.cidrv6;
      description = "The CIDRv6 of this network";
      default = null;
    };

    hosts = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule (hostSubmod: {
          options = {
            id = mkOption {
              type = types.int;
              description = "The id of this host in the network";
            };

            mac = mkOption {
              type = types.nullOr types.net.mac;
              description = "The MAC of the interface on this host that belongs to this network.";
              default = null;
            };

            ipv4 = mkOption {
              type = types.nullOr types.net.ipv4;
              description = "The IPv4 of this host in this network";
              readOnly = true;
              default =
                if netSubmod.config.cidrv4 == null then
                  null
                else
                  lib.net.cidr.host hostSubmod.config.id netSubmod.config.cidrv4;
            };

            ipv6 = mkOption {
              type = types.nullOr types.net.ipv6;
              description = "The IPv6 of this host in this network";
              readOnly = true;
              default =
                if netSubmod.config.cidrv6 == null then
                  null
                else
                  lib.net.cidr.host hostSubmod.config.id netSubmod.config.cidrv6;
            };

            cidrv4 = mkOption {
              type = types.nullOr types.str; # FIXME: this is not types.net.cidr because it would zero out the host part
              description = "The IPv4 of this host in this network, including CIDR mask";
              readOnly = true;
              default =
                if netSubmod.config.cidrv4 == null then
                  null
                else
                  lib.net.cidr.hostCidr hostSubmod.config.id netSubmod.config.cidrv4;
            };

            cidrv6 = mkOption {
              type = types.nullOr types.str; # FIXME: this is not types.net.cidr because it would zero out the host part
              description = "The IPv6 of this host in this network, including CIDR mask";
              readOnly = true;
              default =
                if netSubmod.config.cidrv6 == null then
                  null
                else
                # if we use the /32 wan address as local address directly, do not use the network address in ipv6
                  lib.net.cidr.hostCidr (if hostSubmod.config.id == 0 then 1 else hostSubmod.config.id) netSubmod.config.cidrv6;
            };
          };
        })
      );
    };
  };
in
{
  options = {
    globals = mkOption {
      default = { };
      type = types.submodule {
        options = {
          root = {
            hashedPassword = mkOption {
              type = types.str;
            };
          };

          user = {
            name = mkOption {
              type = types.str;
            };
            work = mkOption {
              type = types.str;
            };
          };


          services = mkOption {
            type = types.attrsOf (
              types.submodule (serviceSubmod: {
                options = {
                  domain = mkOption {
                    type = types.str;
                  };
                  subDomain = mkOption {
                    readOnly = true;
                    type = types.str;
                    default = lib.swarselsystems.getSubDomain serviceSubmod.config.domain;
                  };
                  baseDomain = mkOption {
                    readOnly = true;
                    type = types.str;
                    default = lib.swarselsystems.getBaseDomain serviceSubmod.config.domain;
                  };
                  proxyAddress4 = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                  };
                  proxyAddress6 = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                  };
                };
              })
            );
          };

          networks = mkOption {
            default = { };
            type = types.attrsOf (
              types.submodule (netSubmod: {
                options = networkOptions netSubmod // {
                  vlans = mkOption {
                    default = { };
                    type = types.attrsOf (
                      types.submodule (vlanNetSubmod: {
                        options = networkOptions vlanNetSubmod // {
                          id = mkOption {
                            type = types.ints.between 1 4094;
                            description = "The VLAN id";
                          };

                          name = mkOption {
                            description = "The name of this VLAN";
                            default = vlanNetSubmod.config._module.args.name;
                            type = types.str;
                          };
                        };
                      })
                    );
                  };
                };
              })
            );
          };

          hosts = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {
                  defaultGateway4 = mkOption {
                    type = types.nullOr types.net.ipv4;
                  };
                  defaultGateway6 = mkOption {
                    type = types.nullOr types.net.ipv6;
                  };
                  wanAddress4 = mkOption {
                    type = types.nullOr types.net.ipv4;
                  };
                  wanAddress6 = mkOption {
                    type = types.nullOr types.net.ipv6;
                  };
                };
              }
            );
          };

          domains = {
            main = mkOption {
              type = types.str;
            };
          };
        };
      };
    };

    _globalsDefs = mkOption {
      type = types.unspecified;
      default = options.globals.definitions;
      readOnly = true;
      internal = true;
    };
  };
}
