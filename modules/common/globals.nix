{
  flake.modules.generic.globals =
    {
      inputs,
      lib,
      options,
      ...
    }:
    let
      inherit (lib)
        mkOption
        types
        ;
      inherit (inputs) dns;

      firewallOptions = {
        allowedTCPPortRanges = mkOption {
          default = [ ];
          description = "Convenience option to open specific TCP port ranges for traffic from another node.";
          type = lib.types.listOf (lib.types.attrsOf lib.types.port);
        };
        allowedTCPPorts = mkOption {
          default = [ ];
          description = "Convenience option to open specific TCP ports for traffic from the network.";
          type = types.listOf types.port;
        };
        allowedUDPPortRanges = mkOption {
          default = [ ];
          description = "Convenience option to open specific UDP port ranges for traffic from another node.";
          type = lib.types.listOf (lib.types.attrsOf lib.types.port);
        };
        allowedUDPPorts = mkOption {
          default = [ ];
          description = "Convenience option to open specific UDP ports for traffic from the network.";
          type = types.listOf types.port;
        };
      };

      networkOptions = netSubmod: {
        cidrv4 = mkOption {
          default = null;
          description = "The CIDRv4 of this network";
          type = types.nullOr types.net.cidrv4;
        };
        cidrv6 = mkOption {
          default = null;
          description = "The CIDRv6 of this network";
          type = types.nullOr types.net.cidrv6;
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
                cidrv4 = mkOption {
                  default =
                    if netSubmod.config.cidrv4 == null then
                      null
                    else
                      lib.net.cidr.hostCidr hostSubmod.config.id netSubmod.config.cidrv4;
                  description = "The IPv4 of this host in this network, including CIDR mask";
                  readOnly = true;
                  type = types.nullOr types.str; # FIXME: this is not types.net.cidr because it would zero out the host part
                };
                cidrv6 = mkOption {
                  default =
                    if netSubmod.config.cidrv6 == null then
                      null
                    else
                      # if we use the /32 wan address as local address directly, do not use the network address in ipv6
                      lib.net.cidr.hostCidr (
                        if hostSubmod.config.id == 0 then 1 else hostSubmod.config.id
                      ) netSubmod.config.cidrv6;
                  description = "The IPv6 of this host in this network, including CIDR mask";
                  readOnly = true;
                  type = types.nullOr types.str; # FIXME: this is not types.net.cidr because it would zero out the host part
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
                id = mkOption {
                  description = "The id of this host in the network";
                  type = types.int;
                };
                ipv4 = mkOption {
                  default =
                    if netSubmod.config.cidrv4 == null then
                      null
                    else
                      lib.net.cidr.host hostSubmod.config.id netSubmod.config.cidrv4;
                  description = "The IPv4 of this host in this network";
                  readOnly = true;
                  type = types.nullOr types.net.ipv4;
                };
                ipv6 = mkOption {
                  default =
                    if netSubmod.config.cidrv6 == null then
                      null
                    else
                      lib.net.cidr.host hostSubmod.config.id netSubmod.config.cidrv6;
                  description = "The IPv6 of this host in this network";
                  readOnly = true;
                  type = types.nullOr types.net.ipv6;
                };
                mac = mkOption {
                  default = null;
                  description = "The MAC of the interface on this host that belongs to this network.";
                  type = types.nullOr types.net.mac;
                };
              };
            })
          );
        };
        subnetMask4 = mkOption {
          default = lib.swarselsystems.cidrToSubnetMask netSubmod.config.cidrv4;
          description = "The dotted decimal form of the subnet mask of this network";
          readOnly = true;
          type = types.nullOr types.net.ipv4;
        };
      };
    in
    {
      options = {
        globals = mkOption {
          default = { };
          type = types.submodule {
            options = {
              services = mkOption {
                type = types.attrsOf (
                  types.submodule (serviceSubmod: {
                    options = {
                      baseDomain = mkOption {
                        default = lib.swarselsystems.getBaseDomain serviceSubmod.config.domain;
                        readOnly = true;
                        type = types.str;
                      };
                      domain = mkOption {
                        default = "";
                        description = "The domain under which this service can be reached (empty for internal-only services).";
                        type = types.str;
                      };
                      extraConfig = mkOption {
                        default = { };
                        type = types.attrsOf types.anything;
                      };
                      homeServiceAddress = mkOption {
                        default = null;
                        type = types.nullOr types.str;
                      };
                      isHome = mkOption {
                        default = false;
                        type = types.bool;
                      };
                      proxyAddress4 = mkOption {
                        default = null;
                        type = types.nullOr types.str;
                      };
                      proxyAddress6 = mkOption {
                        default = null;
                        type = types.nullOr types.str;
                      };
                      serviceAddress = mkOption {
                        default = null;
                        type = types.nullOr types.str;
                      };
                      subDomain = mkOption {
                        default = lib.swarselsystems.getSubDomain serviceSubmod.config.domain;
                        readOnly = true;
                        type = types.str;
                      };
                    };
                  })
                );
              };
              dns = mkOption {
                default = { };
                type = types.attrsOf (
                  types.submodule {
                    options.subdomainRecords = mkOption {
                      default = { };
                      type = types.attrsOf dns.lib.types.subzone;
                    };
                  }
                );
              };
              domains = {
                externalDns = mkOption {
                  description = "List of external dns nameservers";
                  type = types.listOf types.str;
                };
                main = mkOption {
                  type = types.str;
                };
              };
              general = lib.mkOption {
                type = types.submodule {
                  freeformType = types.unspecified;
                };
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
                      isHome = mkOption {
                        type = types.bool;
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
              monitoring = mkOption {
                default = { };
                description = "Active probes consumed by each host's local Alloy + blackbox exporter.";
                type = types.submodule {
                  options = {
                    hostNetworks = mkOption {
                      default = { };
                      description = ''
                        Map from hostname to the list of logical monitoring networks that host can
                        probe in; see monitoring.http.<name>.network.
                      '';
                      type = types.attrsOf (types.listOf types.str);
                    };
                    http = mkOption {
                      default = { };
                      type = types.attrsOf (
                        types.submodule {
                          options = {
                            alertFor = mkOption {
                              default = null;
                              description = "How long the probe must stay failed before the alert fires";
                              type = types.nullOr types.str;
                            };
                            expectedBodyRegex = mkOption {
                              default = null;
                              description = "Optional regex that must match the response body.";
                              type = types.nullOr types.str;
                            };
                            expectedStatus = mkOption {
                              default = 200;
                              description = "Status code that signals a healthy response.";
                              type = types.int;
                            };
                            failIfBodyMatchesRegex = mkOption {
                              default = null;
                              description = "Optional regex that marks the probe as failed.";
                              type = types.nullOr types.str;
                            };
                            hostHeader = mkOption {
                              default = null;
                              description = "Optional Host header to send (e.g. for phpfm services).";
                              type = types.nullOr types.str;
                            };
                            network = mkOption {
                              description = ''
                                Logical network tag. The probe is only executed by blackbox sources
                                whose `monitoring.hostNetworks` contains this value.
                              '';
                              type = types.str;
                            };
                            url = mkOption {
                              description = "HTTP(S) URL to probe.";
                              type = types.str;
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
                              description = "Hostname or IP address to ping.";
                              type = types.str;
                            };
                            network = mkOption {
                              description = "Logical network tag; see monitoring.http.<name>.network.";
                              type = types.str;
                            };
                          };
                        }
                      );
                    };
                  };
                };
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
                                description = "The VLAN id";
                                type = types.ints.between 1 4094;
                              };

                              name = mkOption {
                                default = vlanNetSubmod.config._module.args.name;
                                description = "The name of this VLAN";
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
              root.hashedPassword = mkOption {
                type = types.str;
              };
              user = {
                name = mkOption {
                  type = types.str;
                };
                work = mkOption {
                  type = types.str;
                };
              };
              wireguard = mkOption {
                default = { };
                description = "WireGuard network definitions. Each key is a WireGuard interface name.";
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      clients = mkOption {
                        default = [ ];
                        description = "List of client node names participating in this WireGuard network.";
                        type = types.listOf types.str;
                      };
                      netConfigPrefix = mkOption {
                        description = "Prefix used to look up the network in globals.networks.\"<prefix>-<ifName>\".";
                        type = types.str;
                      };
                      port = mkOption {
                        default = 52829;
                        description = "WireGuard listen port on the server.";
                        type = types.int;
                      };
                      server = mkOption {
                        description = "Node name of the WireGuard server for this network.";
                        type = types.str;
                      };
                    };
                  }
                );
              };

            };

          };
        };
        _globalsDefs = mkOption {
          default = options.globals.definitions;
          internal = true;
          readOnly = true;
          type = types.unspecified;
        };
      };
    };
}
