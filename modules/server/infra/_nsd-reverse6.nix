{ globals, ... }:
{
  NS = [
    "soa.${globals.domains.main}."
    "srv.${globals.domains.main}."
  ];

  SOA = {
    adminEmail = "admin@${globals.domains.main}";
    nameServer = "soa.${globals.domains.main}.";
    serial = 2026090902;
  };

  subdomains = globals.dns.${globals.domains.reverse6}.subdomainRecords;
  useOrigin = false;
}
