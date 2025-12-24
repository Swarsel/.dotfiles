{ self, config, lib, globals, inputs, outputs, minimal, nixosConfig ? null, ... }:
{
  _module.args = {
    confLib = rec {

      addressDefault =
        if
          config.swarselsystems.proxyHost != config.node.name
        then
          if
            config.swarselsystems.server.wireguard.interfaces.wgProxy.isClient
          then
            globals.networks."${config.swarselsystems.server.wireguard.interfaces.wgProxy.serverNetConfigPrefix}-wgProxy".hosts.${config.node.name}.ipv4
          else
            globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4
        else
          "localhost";

      domainDefault = service: config.repo.secrets.common.services.domains.${service};
      proxyDefault = config.swarselsystems.proxyHost;

      getConfig = if nixosConfig == null then config else nixosConfig;

      gen = { name, user ? name, group ? name, dir ? null, port ? null, domain ? (domainDefault name), address ? addressDefault, proxy ? proxyDefault }: rec {
        servicePort = port;
        serviceName = name;
        specificServiceName = "${name}-${config.node.name}";
        serviceUser = user;
        serviceGroup = group;
        serviceDomain = domain;
        baseDomain = lib.swarselsystems.getBaseDomain domain;
        subDomain = lib.swarselsystems.getSubDomain domain;
        serviceDir = dir;
        serviceAddress = address;
        serviceProxy = proxy;
        proxyAddress4 = globals.hosts.${proxy}.wanAddress4 or null;
        proxyAddress6 = globals.hosts.${proxy}.wanAddress6 or null;
      };

      mkMicrovm =
        if config.swarselsystems.withMicroVMs then
          (guestName: {
            ${guestName} = {
              backend = "microvm";
              autostart = true;
              modules = [
                (config.node.configDir + /guests/${guestName}.nix)
                {
                  node.secretsDir = config.node.configDir + /secrets/${guestName};
                  node.configDir = config.node.configDir + /guests/${guestName};
                  networking.nftables.firewall = {
                    zones.untrusted.interfaces = lib.mkIf
                      (
                        lib.length config.guests.${guestName}.networking.links == 1
                      )
                      config.guests.${guestName}.networking.links;
                  };
                }
                "${self}/modules/nixos/optional/microvm-guest.nix"
              ];
              microvm = {
                system = config.node.arch;
                baseMac = config.repo.secrets.local.networking.networks.lan.mac;
                interfaces.vlan-services = { };
              };
              extraSpecialArgs = {
                inherit (outputs) nodes;
                inherit (inputs.self.pkgs.${config.node.arch}) lib;
                inherit inputs outputs minimal;
                inherit (inputs) self;
                withHomeManager = false;
                globals = outputs.globals.${config.node.arch};
              };
            };
          }) else (_: { _ = { }; });

    };
  };
}
