# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  outputs = inputs: import ./modules/flake/_outputs.nix inputs;

  inputs = {
    copyparty = {
      url = "github:9001/copyparty/hovudstraum";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    follow-nix = {
      url = "github:Swarsel/follow-nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    glide-nix = {
      url = "github:glide-browser/glide.nix";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunkle = {
      url = "github:Swarsel/hunkle";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    hydra = {
      url = "github:nixos/hydra/nix-2.30";
      inputs.nix-eval-jobs.follows = "nix-eval-jobs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    invidious-companion = {
      url = "https://github.com/iv-org/invidious-companion/releases/download/release-master/invidious_companion-x86_64-unknown-linux-gnu.tar.gz";
      flake = false;
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit.follows = "pre-commit-hooks";
      };
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nginx-otel = {
      url = "github:djvcom/nix-nginx-otel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };
    niritiling = {
      url = "github:Swarsel/niritiling/feat/resize";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-eval-jobs = {
      url = "github:nix-community/nix-eval-jobs";
      flake = false;
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-topology = {
      url = "github:Swarsel/nix-topology/dev";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixos-extra-modules = {
      url = "github:oddlama/nixos-extra-modules/main";
      inputs = {
        devshell.follows = "devshell";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-images.url = "github:Swarsel/nixos-images/main";
    nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
    nixpkgs-kernelpin.url = "github:nixos/nixpkgs/567a49d1913ce81ac6e9582e3553dd90a955875f?narHash=sha256-lrp67w8AulE9Ks53n27I45ADSzbOCn4H%2BCNW1Ck8B%2B8%3D";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable26_05.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgsFirezoneProvisioned.url = "github:nixos/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb?narHash=sha256-3av0pIjlOWQ6rDbNOmpUSvbNnJkGORQKKjb4LtCZsIY%3D";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctoggle = {
      url = "github:Swarsel/noctoggle";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nswitch-rcm-nix = {
      url = "github:Swarsel/nswitch-rcm-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nur-expressions = {
      url = "gitlab:rycee/nur-expressions";
      flake = false;
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    repoSecrets.url = "./secrets/repo";
    shopservatory = {
      url = "github:Swarsel/shopservatory";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";
      inputs = {
        git-hooks.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
      };
    };
    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-l/spicetify-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        nur.follows = "nur";
        systems.follows = "systems";
      };
    };
    swarsel-nix = {
      url = "github:Swarsel/swarsel-nix/main";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    systems.url = "github:nix-systems/default";
    topologyPrivate.url = "./files/topology/public";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vbc-nix = {
      url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
      inputs = {
        nixpkgs.follows = "nixpkgs-stable26_05";
        nixpkgs-2411.follows = "nixpkgs-stable24_11";
        systems.follows = "systems";
      };
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
