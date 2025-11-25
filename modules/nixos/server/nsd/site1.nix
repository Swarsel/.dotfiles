{ config, globals, dns, ... }:
with dns.lib.combinators; {
  SOA = {
    nameServer = "soa";
    adminEmail = "admin@${globals.domains.main}";
    serial = 2025112101;
  };

  useOrigin = false;

  NS = [
    "soa.${globals.domains.name}."
    "ns1.he.net"
    "ns2.he.net"
    "ns3.he.net"
    "ns4.he.net"
    "ns5.he.net"
    "oxygen.ns.hetzner.com"
    "pola.ns.cloudflare.com"
  ];

  A = [ "75.2.60.5" ];

  SRV = [
    {
      service = "_matrix";
      proto = "_tcp";
      port = 443;
      target = "${globals.services.matrix.baseDomain}.${globals.domains.main}";
      priority = 10;
      wweight = 5;
    }
    {
      service = "_submissions";
      proto = "_tcp";
      port = 465;
      target = "${globals.services.mailserver.baseDomain}.${globals.domains.main}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
    {
      service = "_submission";
      proto = "_tcp";
      port = 587;
      target = "${globals.services.mailserver.baseDomain}.${globals.domains.main}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
    {
      service = "_imap";
      proto = "_tcp";
      port = 143;
      target = "${globals.services.mailserver.baseDomain}.${globals.domains.main}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
    {
      service = "_imaps";
      proto = "_tcp";
      port = 993;
      target = "${globals.services.mailserver.baseDomain}.${globals.domains.main}";
      priority = 5;
      weight = 0;
      ttl = 3600;
    }
  ];

  MX = [
    {
      preference = 10;
      exchange = "${globals.services.mailserver.baseDomain}.${globals.domains.main}";
    }
  ];

  CNAME = [
    {
      cname = "www.${glovals.domains.main}";
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

  DMARC = [
    {
      p = "none";
      ttl = 10800;
    }
  ];

  TXT = [
    (with spf; strict [ "a:${globals.services.mailserver.baseDomain}.${globals.domains.main}" ])
    "google-site-verification=${config.repo.secrets.local.dns.google-site-verification}"
  ];

  DMARC = [
    {
      selector = "mail";
      k = "rsa";
      p = "none";
      ttl = 10800;
    }
  ];

  subdomains = config.swarselsystems.server.dns.${globals.domain.main}.subdomainRecords // {
    "minecraft" = host "130.61.119.12" null;
  };
}
