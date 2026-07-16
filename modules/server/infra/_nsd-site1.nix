{
  config,
  dns,
  globals,
  proxyAddress4,
  proxyAddress6,
  ...
}:
with dns.lib.combinators;
{
  A = [ config.repo.secrets.local.dns.homepage-ip ];

  CAA = [
    {
      issuerCritical = false;
      tag = "issue";
      value = "letsencrypt.org";
    }
    {
      issuerCritical = false;
      tag = "issuewild";
      value = "letsencrypt.org";
    }
    {
      issuerCritical = false;
      tag = "iodef";
      value = "mailto:${config.repo.secrets.common.dnsMail}";
    }
  ];

  DKIM = [
    {
      k = "rsa";
      p = config.repo.secrets.local.dns.mailserver.dkim-public;
      selector = "mail";
      ttl = 10800;
    }
  ];

  DMARC = [
    {
      p = "none";
      ttl = 10800;
    }
  ];

  MX = [
    {
      exchange = "${globals.services.mailserver.subDomain}";
      preference = 10;
    }
  ];

  NS = [
    "soa"
    "srv"
  ]
  ++ globals.domains.externalDns;

  SOA = {
    adminEmail = "admin@${globals.domains.main}"; # this option is not parsed as domain (we cannot just write "admin")
    nameServer = "soa";
    serial = 2026062601; # update this on changes for secondary dns
  };

  SRV = [
    {
      port = 443;
      priority = 10;
      proto = "_tcp";
      service = "_matrix";
      target = "${globals.services.matrix.subDomain}";
      weight = 5;
    }
    {
      port = 465;
      priority = 5;
      proto = "_tcp";
      service = "_submissions";
      target = "${globals.services.mailserver.subDomain}";
      ttl = 3600;
      weight = 0;
    }
    {
      port = 587;
      priority = 5;
      proto = "_tcp";
      service = "_submission";
      target = "${globals.services.mailserver.subDomain}";
      ttl = 3600;
      weight = 0;
    }
    {
      port = 143;
      priority = 5;
      proto = "_tcp";
      service = "_imap";
      target = "${globals.services.mailserver.subDomain}";
      ttl = 3600;
      weight = 0;
    }
    {
      port = 993;
      priority = 5;
      proto = "_tcp";
      service = "_imaps";
      target = "${globals.services.mailserver.subDomain}";
      ttl = 3600;
      weight = 0;
    }
  ];

  TXT = [
    (with spf; strict [ "a:${globals.services.mailserver.subDomain}.${globals.domains.main}" ])
    "google-site-verification=${config.repo.secrets.local.dns.google-site-verification}"
  ];

  subdomains = globals.dns.${globals.domains.main}.subdomainRecords // {
    "_acme-challenge".CNAME = [ "${config.repo.secrets.local.dns.acme-challenge-domain}." ];
    "soa" = host proxyAddress4 proxyAddress6;
    "srv" = host proxyAddress4 proxyAddress6;
    "www".CNAME = [ "${globals.domains.main}." ];
  };

  useOrigin = false;
}
