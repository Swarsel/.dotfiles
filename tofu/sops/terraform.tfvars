pgp_key          = "4BE7925262289B476DBBC17B76FD3810215AE097"
buildbot_age_key = "age15dewhja45kljg3ehd6anzwlxmavaf8wpqqj0gf6u859kd5v70ves6zkxr7"

extra_rules = [
  {
    path_regex = "secrets/work/[^/]+\\.enc$"
    age_keys   = ["pyramid", "treehouse", "buildbot"]
  },
]

host_configs = {
  pyramid = {
    type   = "nixos"
    arch   = "x86_64-linux"
    guests = []
  }
  bakery = {
    type   = "nixos"
    arch   = "x86_64-linux"
    guests = []
  }
  toto = {
    type   = "nixos"
    arch   = "x86_64-linux"
    guests = []
  }
  winters = {
    type   = "nixos"
    arch   = "x86_64-linux"
    guests = []
  }
  eagleland = {
    type   = "nixos"
    arch   = "x86_64-linux"
    guests = []
  }
  summers = {
    type = "nixos"
    arch = "x86_64-linux"
    guests = [
      "ankisync",
      "atuin",
      "audio",
      "dawarich",
      "firefly",
      "forgejo",
      "freshrss",
      "homebox",
      "immich",
      "jellyfin",
      "kanidm",
      "kavita",
      "koillection",
      "matrix",
      "mealie",
      "monitoring",
      "nextcloud",
      "paperless",
      "radicale",
      "storage",
      "transmission",
      "utility",
    ]
  }
  hintbooth = {
    type   = "nixos"
    arch   = "x86_64-linux"
    guests = ["adguardhome", "nginx"]
  }
  moonside = {
    type   = "nixos"
    arch   = "aarch64-linux"
    guests = []
  }
  belchsfactory = {
    type   = "nixos"
    arch   = "aarch64-linux"
    guests = []
  }
  stoicclub = {
    type   = "nixos"
    arch   = "aarch64-linux"
    guests = []
  }
  liliputsteps = {
    type   = "nixos"
    arch   = "aarch64-linux"
    guests = []
  }
  twothreetunnel = {
    type   = "nixos"
    arch   = "aarch64-linux"
    guests = []
  }
  machpizza = {
    type   = "darwin"
    arch   = "aarch64-darwin"
    guests = []
  }
  vacanthouse = {
    type        = "utility"
    arch        = "x86_64-linux"
    path        = "hosts/utility/vacanthouse"
    guests      = []
    repo_access = false
  }
}
