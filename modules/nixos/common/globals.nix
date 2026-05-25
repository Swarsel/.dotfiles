{ lib, inputs, options, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (inputs) dns;

  firewallOptions = {
    allowedTCPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      description = "Convenience option to open specific TCP ports for traffic from the network.";
    };
    allowedUDPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      description = "Convenience option to open specific UDP ports for traffic from the network.";
    };
    allowedTCPPortRanges = mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.port);
      default = [ ];
      description = "Convenience option to open specific TCP port ranges for traffic from another node.";
    };
    allowedUDPPortRanges = mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.port);
      default = [ ];
      description = "Convenience option to open specific UDP port ranges for traffic from another node.";
    };
  };

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

    firewallRuleForAll = mkOption {
      default = { };
      description = ''
        If this is a wireguard network: Allows you to set specific firewall rules for traffic originating from any participant in this
        wireguard network. A corresponding rule `<network-name>-to-<local-zone-name>` will be created to easily expose
        services to the network.
      '';
      type = types.submodule {
        options = firewallOptions;
      };
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

            firewallRuleForNode = mkOption {
              default = { };
              description = ''
                If this is a wireguard network: Allows you to set specific firewall rules just for traffic originating from another network node.
                A corresponding rule `<network-name>-node-<node-name>-to-<local-zone-name>` will be created to easily expose
                services to that node.
              '';
              type = types.attrsOf (
                types.submodule {
                  options = firewallOptions;
                }
              );
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
                    default = "";
                    description = "The domain under which this service can be reached (empty for internal-only services).";
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
                  serviceAddress = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                  };
                  homeServiceAddress = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                  };
                  isHome = mkOption {
                    type = types.bool;
                    default = false;
                  };
                  extraConfig = mkOption {
                    type = types.attrs;
                    default = { };
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
                  isHome = mkOption {
                    type = types.bool;
                  };
                };
              }
            );
          };

          wireguard = mkOption {
            default = { };
            description = "WireGuard network definitions. Each key is a WireGuard interface name.";
            type = types.attrsOf (
              types.submodule {
                options = {
                  server = mkOption {
                    type = types.str;
                    description = "Node name of the WireGuard server for this network.";
                  };

                  netConfigPrefix = mkOption {
                    type = types.str;
                    description = "Prefix used to look up the network in globals.networks.\"<prefix>-<ifName>\".";
                  };

                  port = mkOption {
                    type = types.int;
                    default = 52829;
                    description = "WireGuard listen port on the server.";
                  };

                  clients = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "List of client node names participating in this WireGuard network.";
                  };
                };
              }
            );
          };

          domains = {
            main = mkOption {
              type = types.str;
            };
            externalDns = mkOption {
              type = types.listOf types.str;
              description = "List of external dns nameservers";
            };
          };

          general = lib.mkOption {
            type = types.submodule {
              freeformType = types.unspecified;
            };
          };

          dns = mkOption {
            default = { };
            type = types.attrsOf (
              types.submodule {
                options = {
                  subdomainRecords = mkOption {
                    type = types.attrsOf dns.lib.types.subzone;
                    default = { };
                  };
                };
              }
            );
          };

          monitoring = mkOption {
            default = { };
            description = "Active probes consumed by each host's local Alloy + blackbox exporter.";
            type = types.submodule {
              options = {
                http = mkOption {
                  default = { };
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        url = mkOption {
                          type = types.str;
                          description = "HTTP(S) URL to probe.";
                        };
                        expectedStatus = mkOption {
                          type = types.int;
                          default = 200;
                          description = "Status code that signals a healthy response.";
                        };
                        expectedBodyRegex = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                          description = "Optional regex that must match the response body.";
                        };
                        failIfBodyMatchesRegex = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                          description = "Optional regex that marks the probe as failed.";
                        };
                        hostHeader = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                          description = "Optional Host header to send (e.g. for phpfm services).";
                        };
                        network = mkOption {
                          type = types.str;
                          description = ''
                            Logical network tag. The probe is only executed by blackbox sources
                            whose `monitoring.hostNetworks` contains this value.
                          '';
                        };
                      };
                    }
                  );
                };

                ping = mkOption {
                  default = { };
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        host = mkOption {
                          type = types.str;
                          description = "Hostname or IP address to ping.";
                        };
                        network = mkOption {
                          type = types.str;
                          description = "Logical network tag; see monitoring.http.<name>.network.";
                        };
                      };
                    }
                  );
                };

                hostNetworks = mkOption {
                  default = { };
                  description = ''
                    Map from hostname to the list of logical monitoring networks that host can
                    probe in; see monitoring.http.<name>.network.
                  '';
                  type = types.attrsOf (types.listOf types.str);
                };
              };
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
