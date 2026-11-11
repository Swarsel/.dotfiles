{
  config,
  dmarcMailAddress,
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
      rua = "mailto:${dmarcMailAddress}";
      ttl = 10800;
    }
  ];

  MX = [
    {
      exchange = globals.services.mailserver.subDomain;
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
    serial = 2026102901;
  };

  SRV = [
    {
      port = 443;
      priority = 10;
      proto = "_tcp";
      service = "_matrix";
      target = globals.services.matrix.subDomain;
      weight = 5;
    }
  ]
  ++
    map
      (
        record:
        record
        // {
          priority = 5;
          proto = "_tcp";
          target = globals.services.mailserver.subDomain;
          ttl = 3600;
          weight = 0;
        }
      )
      [
        {
          port = 465;
          service = "_submissions";
        }
        {
          port = 587;
          service = "_submission";
        }
        {
          port = 143;
          service = "_imap";
        }
        {
          port = 993;
          service = "_imaps";
        }
      ];

  TXT = [
    (with spf; strict [ "a:${globals.services.mailserver.subDomain}.${globals.domains.main}" ])
    "google-site-verification=${config.repo.secrets.local.dns.google-site-verification}"
  ];

  subdomains =
    globals.dns.${globals.domains.main}.subdomainRecords
    // builtins.listToAttrs (
      map
        (port: {
          name = "_${toString port}._tcp.${globals.services.mailserver.subDomain}";
          value.TLSA = [
            {
              certUsage = "dane-ee";
              certificate = "c012bcab175ceadb422f964fdeb1c5aa778f8efae9d46f37f7717456cbc61467";
              matchingType = "sha256";
              selector = "spki";
            }
          ];
        })
        [
          25
          465
          587
          993
        ]
    )
    // {
      _acme-challenge.CNAME = [ "${config.repo.secrets.local.dns.acme-challenge-domain}." ];
      soa = host proxyAddress4 proxyAddress6;
      srv = host proxyAddress4 proxyAddress6;
      www.CNAME = [ "${globals.domains.main}." ];
    }
    // config.repo.secrets.local.dns.extra-records;

  useOrigin = false;
}
