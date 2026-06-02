{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-kernelpin.url = "github:nixos/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61?narHash=sha256-I45esRSssFtJ8p/gLHUZ1OUaaTaVLluNkABkk6arQwE%3D"; #specifically pinned for kernel version
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable25_11.url = "github:NixOS/nixpkgs/nixos-25.11";

    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nginx-otel = {
      url = "github:djvcom/nix-nginx-otel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      # url = "github:swarsel/emacs-overlay/fix";
      # url = "github:nix-community/emacs-overlay/aba8daa237dc07a3bb28a61c252a718e8eb38057?narHash=sha256-4OXXccXsY1sBXTXjYIthdjXLAotozSh4F8StGRuLyMQ%3D";
      url = "github:nix-community/emacs-overlay";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    invidious-companion = {
      url = "https://github.com/iv-org/invidious-companion/releases/download/release-master/invidious_companion-x86_64-unknown-linux-gnu.tar.gz";
      flake = false;
    };


    topologyPrivate.url = "./files/topology/public";

    swarsel-nix.url = "github:Swarsel/swarsel-nix/main";
    systems.url = "github:nix-systems/default";
    nur.url = "github:nix-community/NUR";
    nixgl.url = "github:guibou/nixGL";
    stylix.url = "github:danth/stylix";
    sops.url = "github:Mic92/sops-nix";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nixos-images.url = "github:Swarsel/nixos-images/main";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nswitch-rcm-nix.url = "github:Swarsel/nswitch-rcm-nix";
    disko.url = "github:nix-community/disko";
    impermanence.url = "github:nix-community/impermanence";
    zjstatus.url = "github:dj95/zjstatus";
    nix-darwin.url = "github:lnl7/nix-darwin";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    vbc-nix.url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
    nix-topology.url = "github:oddlama/nix-topology";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    spicetify-nix.url = "github:Gerg-l/spicetify-nix";
    niri-flake.url = "github:sodiboo/niri-flake";
    nixos-extra-modules.url = "github:oddlama/nixos-extra-modules/main";
    microvm.url = "github:astro/microvm.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";
    nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";
    niritiling.url = "github:Swarsel/niritiling/feat/resize";
    noctoggle.url = "github:Swarsel/noctoggle";
    copyparty = {
      url = "github:9001/copyparty/hovudstraum";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nix/globals.nix
        ./nix/hosts.nix
        ./nix/topology.nix
        ./nix/devshell.nix
        ./nix/apps.nix
        ./nix/packages.nix
        ./nix/overlays.nix
        ./nix/lib.nix
        ./nix/templates.nix
        ./nix/formatter.nix
        ./nix/modules.nix
        ./nix/iso.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
}
