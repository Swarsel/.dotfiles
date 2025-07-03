{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.ngi0.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-kernel.url = "github:NixOS/nixpkgs/063f43f2dbdef86376cc29ad646c45c46e93234c?narHash=sha256-6m1Y3/4pVw1RWTsrkAK2VMYSzG4MMIj7sqUy7o8th1o%3D"; #specifically pinned for kernel version
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    nixgl.url = "github:guibou/nixGL";
    stylix.url = "github:danth/stylix";
    sops-nix.url = "github:Mic92/sops-nix";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
    };
    nswitch-rcm-nix = {
      url = "github:Swarsel/nswitch-rcm-nix";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    zjstatus = {
      url = "github:dj95/zjstatus";
    };
    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "git+ssh://git@github.com/Swarsel/nix-secrets.git?ref=main&shallow=1";
      flake = false;
      inputs = { };
    };
    vbc-nix = {
      url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-topology.url = "github:oddlama/nix-topology";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
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
