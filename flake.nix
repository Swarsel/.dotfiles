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
    hydra.url = "github:nixos/hydra/nix-2.30";
    # hydra.inputs.nix.follows = "nix";
    hydra.inputs.nix-eval-jobs.follows = "nix-eval-jobs";
    # nix = {
    #   url = "github:NixOS/nix/2.30-maintenance";
    #   # We want to control the deps precisely
    #   flake = false;
    # };
    nix-eval-jobs = {
      url = "github:nix-community/nix-eval-jobs/v2.30.0";
      # We want to control the deps precisely
      flake = false;
    };

    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";
    nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
    nixpkgs-kernel.url = "github:NixOS/nixpkgs/063f43f2dbdef86376cc29ad646c45c46e93234c?narHash=sha256-6m1Y3/4pVw1RWTsrkAK2VMYSzG4MMIj7sqUy7o8th1o%3D"; #specifically pinned for kernel version
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      # url = "github:nix-community/home-manager";
      url = "github:Swarsel/home-manager/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.url = "github:nix-community/emacs-overlay/aba8daa237dc07a3bb28a61c252a718e8eb38057?narHash=sha256-4OXXccXsY1sBXTXjYIthdjXLAotozSh4F8StGRuLyMQ%3D";
    swarsel-nix.url = "github:Swarsel/swarsel-nix/main";
    systems.url = "github:nix-systems/default";
    nur.url = "github:nix-community/NUR";
    nixgl.url = "github:guibou/nixGL";
    stylix.url = "github:danth/stylix";
    sops.url = "github:Mic92/sops-nix";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nixos-generators.url = "github:nix-community/nixos-generators";
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
    dns.url = "github:kirelagin/dns.nix";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";
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
