{ config, lib, globals, nixosConfig ? null, ... }:
{
  _module.args = {
    confLib = rec {

      addressDefault = if config.swarselsystems.proxyHost != config.node.name then globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4 else "localhost";

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
    };
  };
}
