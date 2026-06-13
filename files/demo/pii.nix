{
  ipv4 = "203.0.113.1";
  wireguardEndpoint = "vpn.example.org";
  atticPublicKey = "demo:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  sportDomain = "sport.example.org";
  instaDomain = "insta.example.org";

  noctaliaGithubToken = "";

  builder1-ip = "203.0.113.2";
  builder1-pubHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
  builder1-pubHostKey-b64 = "";
  builder2-ip = "203.0.113.3";
  builder2-pubHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
  builder2-pubHostKey-b64 = "";
  jump-pubHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
  jump-pubHostKey-b64 = "";

  dnsProvider = "example";
  dnsBase = "example.org";
  dnsMail = "hostmaster@example.org";
  openrouterApi = "";
  emacs.radicaleUser = "demo";
  irc.irc_nick1 = "demo";
  fullName = "Demo User";
  workHostName = "demo-work";
  caldavTasksEndpoint = "https://radicale.example.org/demo/tasks/";

  location = {
    timezone = "Europe/Vienna";
    timezoneSpecific = "Europe/Vienna";
    latitude = "16.0";
    longitude = "16.0";
  };

  syncthing = {
    devices = {
      demo1.id = "AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA";
      demo2.id = "AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAB";
    };
  };

  obsidian = {
    userIgnoreFilters = [ ];
  };

  calendar = {
    source1 = "https://calendar.example.org/demo/calendar1/";
    source1-name = "calendar1";
    source2 = "https://calendar.example.org/demo/calendar2/";
    source2-name = "calendar2";
    source3 = "https://calendar.example.org/demo/calendar3/";
    source3-name = "calendar3";
  };

  mail = {
    address1 = "demo@example.org";
    address2 = "demo2@example.org";
    address2-name = "demo2";
    address3 = "demo3@example.org";
    address3-name = "demo3";
    address4 = "demo4@example.org";
    addressWork = "demo@work.example.org";
    addressWork-name = "demo-work";
    allMailAddresses = "demo@example.org demo2@example.org demo3@example.org demo4@example.org";
  };

  yubikeys = {
    dev1 = "0000000";
    cfg1 = "00000000000000000000000000000000";
    dev2 = "0000001";
    cfg2 = "00000000000000000000000000000001";
  };

  network = {
    wlan1 = "DemoWifi";
    wlan2 = "DemoWifi2";
    mobile1 = "DemoHotspot";
    eduroam-anon = "anonymous@example.org";
    vpn1-location = "demo";
    vpn1-cipher = "aes-256-gcm";
    vpn1-address = "vpn.example.org";
  };

  services.domains = {
    kavita = "kavita.example.org";
    jellyfin = "jellyfin.example.org";
    navidrome = "navidrome.example.org";
    matrix = "matrix.example.org";
    nextcloud = "nextcloud.example.org";
    immich = "immich.example.org";
    paperless = "paperless.example.org";
    syncthing1 = "syncthing1.example.org";
    syncthing-summers-storage = "syncthing-storage.example.org";
    syncthing2 = "syncthing2.example.org";
    syncthing3 = "syncthing3.example.org";
    syncthing-moonside = "syncthing-moonside.example.org";
    grafana = "grafana.example.org";
    jenkins = "jenkins.example.org";
    freshrss = "freshrss.example.org";
    forgejo = "forgejo.example.org";
    ankisync = "ankisync.example.org";
    kanidm = "kanidm.example.org";
    oauth2-proxy = "oauth2-proxy.example.org";
    firefly-iii = "firefly.example.org";
    koillection = "koillection.example.org";
    atuin = "atuin.example.org";
    radicale = "radicale.example.org";
    croc = "croc.example.org";
    microbin = "microbin.example.org";
    shlink = "shlink.example.org";
    slink = "slink.example.org";
    transmission = "transmission.example.org";
    snipeit = "snipeit.example.org";
    homebox = "homebox.example.org";
    garage-belchsfactory = "garage1.example.org";
    garage-winters = "garage2.example.org";
    minecraft = "minecraft.example.org";
    mailserver = "mail.example.org";
    attic = "attic.example.org";
    garage-web-belchsfactory = "garage-web1.example.org";
    garage-web-winters = "garage-web2.example.org";
    garage-admin-belchsfactory = "garage-admin1.example.org";
    garage-admin-winters = "garage-admin2.example.org";
    hydra = "hydra.example.org";
    buildbot = "buildbot.example.org";
    roundcube = "roundcube.example.org";
    firezone = "firezone.example.org";
    adguardhome = "adguardhome.example.org";
    searx = "searx.example.org";
    invidious = "invidious.example.org";
    firefox-syncserver = "firefox-sync.example.org";
    loki = "loki.example.org";
    tempo = "tempo.example.org";
    mimir = "mimir.example.org";
    pyroscope = "pyroscope.example.org";
    gotify = "gotify.example.org";
    copyparty = "copyparty.example.org";
    mealie = "mealie.example.org";
  };

  ssh.hosts = { };
}
