{ config, globals, dns, proxyAddress4, proxyAddress6, ... }:
with dns.lib.combinators; {
  SOA = {
    nameServer = "soa";
    adminEmail = "admin@${globals.domains.main}"; # this option is not parsed as domain (we cannot just write "admin")
    serial = 2025120203; # update this on changes for secondary dns
  };

  useOrigin = false;

  NS = [
    "soa"
    "srv"
  ] ++ globals.domains.externalDns;


  A = [ config.repo.secrets.local.dns.homepage-ip ];

  SRV = [
    {
      service = "_matrix";
      proto = "_tcp";
      port = 443;
      target = "${globals.services.matrix.subDomain}";
      priority = 10;
      weight = 5;
    }
    {
      service = "_submissions";
      proto = "_tcp";
      port = 465;
      target = "${globals.services.mailserver.subDomain}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
    {
      service = "_submission";
      proto = "_tcp";
      port = 587;
      target = "${globals.services.mailserver.subDomain}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
    {
      service = "_imap";
      proto = "_tcp";
      port = 143;
      target = "${globals.services.mailserver.subDomain}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
    {
      service = "_imaps";
      proto = "_tcp";
      port = 993;
      target = "${globals.services.mailserver.subDomain}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
  ];

  MX = [
    {
      preference = 10;
      exchange = "${globals.services.mailserver.subDomain}";
    }
  ];

  DKIM = [
    {
      selector = "mail";
      k = "rsa";
      p = config.repo.secrets.local.dns.mailserver.dkim-public;
      ttl = 10800;
    }
  ];

  TXT = [
    (with spf; strict [ "a:${globals.services.mailserver.subDomain}.${globals.domains.main}" ])
    "google-site-verification=${config.repo.secrets.local.dns.google-site-verification}"
  ];

  DMARC = [
    {
      p = "none";
      ttl = 10800;
    }
  ];

  subdomains = config.swarselsystems.server.dns.${globals.domains.main}.subdomainRecords // {
    "www".CNAME = [ "${globals.domains.main}." ];
    "_acme-challenge".CNAME = [ "${config.repo.secrets.local.dns.acme-challenge-domain}." ];
    "soa" = host proxyAddress4 proxyAddress6;
    "srv" = host proxyAddress4 proxyAddress6;
  };
}
