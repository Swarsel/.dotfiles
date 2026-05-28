{ self, lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "slink"; port = 3000; dir = "/var/lib/slink"; }) servicePort serviceName serviceDomain serviceDir serviceAddress proxyAddress4 proxyAddress6 topologyContainerName;
  inherit (confLib.static) isHome webProxy homeWebProxy idmServer homeServiceAddress nginxAccessRules;

  containerRev = "sha256:98b9442696f0a8cbc92f0447f54fa4bad227af5dcfd6680545fedab2ed28ddd9";
in
{
  imports = [
    "${self}/modules/nixos/server/podman.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "slink" ];


    topology.nodes.${topologyContainerName}.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "services.not-available";
    };

    virtualisation.oci-containers.containers.${serviceName} = {
      image = "anirdev/slink@${containerRev}";
      environment = {
        "ORIGIN" = "https://${serviceDomain}";
        "TZ" = config.repo.secrets.common.location.timezone;
        "STORAGE_PROVIDER" = "local";
        "IMAGE_MAX_SIZE" = "50M";
        "USER_APPROVAL_REQUIRED" = "true";
      };
      ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
      volumes = [
        "${serviceDir}/var/data:/app/var/data"
        "${serviceDir}/images:/app/slink/images"
      ];
    };

    systemd.tmpfiles.settings."12-slink" = builtins.listToAttrs (
      map
        (path: {
          name = "${serviceDir}/${path}";
          value = {
            d = {
              group = "root";
              user = "root";
              mode = "0750";
            };
          };
        }) [
        "var/data"
        "images"
      ]
    );

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; }
    ];

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
    };


    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes =
      let
        genNginx = toAddress: extraConfig: {
          upstreams = {
            ${serviceName} = {
              servers = {
                "${toAddress}:${builtins.toString servicePort}" = { };
              };
            };
          };
          virtualHosts = {
            "${serviceDomain}" = {
              useACMEHost = globals.domains.main;

              forceSSL = true;
              acmeRoot = null;
              oauth2 = {
                enable = true;
                allowedGroups = [ "slink_access" ];
              };
              inherit extraConfig;
              locations = {
                "/" = {
                  proxyPass = "http://${serviceName}";
                };
                "/image" = {
                  proxyPass = "http://${serviceName}";
                  setOauth2Headers = false;
                  bypassAuth = true;
                };
              };
            };
          };
        };
      in
      {
        ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
      };

  };
}
