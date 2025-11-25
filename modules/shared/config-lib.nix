{ config, globals, ... }:
{
  _module.args = {
    confLib = rec {

      addressDefault = if config.swarselsystems.proxyHost != config.node.name then globals.networks."${if config.swarselsystems.isCloud then config.node.name else "home"}-${config.swarselsystems.server.localNetwork}".hosts.${config.node.name}.ipv4 else "localhost";

      domainDefault = service: config.repo.secrets.common.services.domains.${service};
      proxyDefault = config.swarselsystems.proxyHost;

      gen = { name, user ? name, group ? name, dir ? null, port ? null, domain ? (domainDefault name), address ? addressDefault, proxy ? proxyDefault }: rec {
        servicePort = port;
        serviceName = name;
        serviceUser = user;
        serviceGroup = group;
        serviceDomain = domain;
        serviceDir = dir;
        serviceAddress = address;
        serviceProxy = proxy;
        proxyAddress4 = globals.hosts.${proxy}.wanAddress4;
        proxyAddress6 = globals.hosts.${proxy}.wanAddress6 or null;
      };
    };
  };
}
