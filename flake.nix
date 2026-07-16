# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  inputs = {
    copyparty = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:9001/copyparty/hovudstraum";
    };

    devshell = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/devshell";
    };

    disko = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/disko";
    };

    dns = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:kirelagin/dns.nix";
    };

    emacs-overlay = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
      url = "github:nix-community/emacs-overlay";
    };

    flake-file.url = "github:vic/flake-file";

    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };

    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };

    follow-nix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/follow-nix";
    };

    glide-nix = {
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:glide-browser/glide.nix";
    };

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };

    hunkle = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/hunkle";
    };

    hydra = {
      inputs.nix-eval-jobs.follows = "nix-eval-jobs";
      url = "github:nixos/hydra/nix-2.30";
    };

    impermanence = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/impermanence";
    };

    import-tree.url = "github:vic/import-tree";

    invidious-companion = {
      flake = false;
      url = "https://github.com/iv-org/invidious-companion/releases/download/release-master/invidious_companion-x86_64-unknown-linux-gnu.tar.gz";
    };

    lanzaboote = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit.follows = "pre-commit-hooks";
      };
      url = "github:nix-community/lanzaboote";
    };

    microvm = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:astro/microvm.nix";
    };

    nginx-otel = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:djvcom/nix-nginx-otel";
    };

    niri-flake = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
      url = "github:sodiboo/niri-flake";
    };

    niritiling = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/niritiling";
    };

    nix-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:lnl7/nix-darwin";
    };

    nix-eval-jobs = {
      flake = false;
      url = "github:nix-community/nix-eval-jobs";
    };

    nix-index-database = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nix-index-database";
    };

    nix-minecraft = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
      url = "github:Infinidoge/nix-minecraft";
    };

    nix-on-droid = {
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:nix-community/nix-on-droid/release-24.05";
    };

    nix-topology = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:Swarsel/nix-topology/dev";
    };

    nixgl = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:guibou/nixGL";
    };

    nixos-extra-modules = {
      inputs = {
        devshell.follows = "devshell";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
      url = "github:oddlama/nixos-extra-modules/main";
    };

    nixos-generators = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixos-generators";
    };

    nixos-hardware = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:NixOS/nixos-hardware/master";
    };

    nixos-images.url = "github:Swarsel/nixos-images/main";
    nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
    nixpkgs-kernelpin.url = "github:nixos/nixpkgs/567a49d1913ce81ac6e9582e3553dd90a955875f?narHash=sha256-lrp67w8AulE9Ks53n27I45ADSzbOCn4H%2BCNW1Ck8B%2B8%3D";
    nixpkgs-sandbox.url = "github:tebriel/nixpkgs/homebox/0.26.2";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable26_05.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgsFirezoneProvisioned.url = "github:nixos/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb?narHash=sha256-3av0pIjlOWQ6rDbNOmpUSvbNnJkGORQKKjb4LtCZsIY%3D";

    noctalia = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:noctalia-dev/noctalia-shell";
    };

    noctalia-greeter = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:noctalia-dev/noctalia-greeter";
    };

    noctoggle = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/noctoggle";
    };

    nswitch-rcm-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Swarsel/nswitch-rcm-nix";
    };

    nur = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:nix-community/NUR";
    };

    nur-expressions = {
      flake = false;
      url = "gitlab:rycee/nur-expressions";
    };

    pedantix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/pedantix";
    };

    pre-commit-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };

    repoSecrets.url = "./secrets/repo";

    shopservatory = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/shopservatory";
    };

    simple-nixos-mailserver = {
      inputs = {
        git-hooks.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
      };
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";
    };

    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";

    sops = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };

    spicetify-nix = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
      url = "github:Gerg-l/spicetify-nix";
    };

    stylix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        nur.follows = "nur";
        systems.follows = "systems";
      };
      url = "github:danth/stylix";
    };

    swarsel-nix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
      url = "github:Swarsel/swarsel-nix/main";
    };

    systems.url = "github:nix-systems/default";
    topologyPrivate.url = "./files/topology/public";

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };

    vbc-nix = {
      inputs = {
        nixpkgs.follows = "nixpkgs-stable26_05";
        nixpkgs-2411.follows = "nixpkgs-stable24_11";
        systems.follows = "systems";
      };
      url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
    };

    zjstatus = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:dj95/zjstatus";
    };
  };

  outputs = inputs: import ./modules/flake/_outputs.nix inputs;
}
