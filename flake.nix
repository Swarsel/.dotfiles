# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "SwarseFlake - Nix Flake for all SwarselSystems";

  outputs = inputs: import ./modules/flake/_outputs.nix inputs;

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    copyparty = {
      url = "github:9001/copyparty/hovudstraum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell.url = "github:numtide/devshell";
    disko.url = "github:nix-community/disko";
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    flake-file.url = "github:vic/flake-file";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hydra = {
      url = "github:nixos/hydra/nix-2.30";
      inputs.nix-eval-jobs.follows = "nix-eval-jobs";
    };
    impermanence.url = "github:nix-community/impermanence";
    import-tree.url = "github:vic/import-tree";
    invidious-companion = {
      url = "https://github.com/iv-org/invidious-companion/releases/download/release-master/invidious_companion-x86_64-unknown-linux-gnu.tar.gz";
      flake = false;
    };
    lanzaboote.url = "github:nix-community/lanzaboote";
    microvm.url = "github:astro/microvm.nix";
    nginx-otel = {
      url = "github:djvcom/nix-nginx-otel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake.url = "github:sodiboo/niri-flake";
    niritiling.url = "github:Swarsel/niritiling/feat/resize";
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
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-topology.url = "github:oddlama/nix-topology";
    nixgl.url = "github:guibou/nixGL";
    nixos-extra-modules.url = "github:oddlama/nixos-extra-modules/main";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-images.url = "github:Swarsel/nixos-images/main";
    nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
    nixpkgs-kernelpin.url = "github:nixos/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61?narHash=sha256-I45esRSssFtJ8p/gLHUZ1OUaaTaVLluNkABkk6arQwE%3D";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable25_11.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctoggle.url = "github:Swarsel/noctoggle";
    nswitch-rcm-nix.url = "github:Swarsel/nswitch-rcm-nix";
    nur.url = "github:nix-community/NUR";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";
    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";
    sops.url = "github:Mic92/sops-nix";
    spicetify-nix.url = "github:Gerg-l/spicetify-nix";
    stylix.url = "github:danth/stylix";
    swarsel-nix.url = "github:Swarsel/swarsel-nix/main";
    systems.url = "github:nix-systems/default";
    topologyPrivate.url = "./files/topology/public";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    vbc-nix.url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
    zjstatus.url = "github:dj95/zjstatus";
  };
}
