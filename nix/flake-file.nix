{ self, inputs, ... }:
let
  realLib = inputs.nixpkgs.lib;

  discoverRoots = [
    ../modules
    ../hosts
    ../profiles
  ];

  declaresFlakeInput =
    path:
    realLib.lists.any
      (line: builtins.match "[[:space:]]*flake-file\\.inputs[. =].*" line != null)
      (realLib.splitString "\n" (builtins.readFile path));

  discoveredModules = realLib.pipe discoverRoots [
    (map realLib.filesystem.listFilesRecursive)
    realLib.lists.flatten
    (builtins.filter (p: realLib.hasSuffix ".nix" (toString p)))
    (builtins.filter declaresFlakeInput)
  ];

  metadataModules = [ ./flake-file-options.nix ] ++ discoveredModules;

  metadata = realLib.evalModules {
    specialArgs = {
      inherit self;
      inputs = { };
      outputs = { };
      lib = realLib;
      config = { };
      globals = { };
      confLib = { };
      homeLib = { };
      nodes = { };
      topologyPrivate = { };
      minimal = false;
      configName = "_flake-file-metadata";
      arch = "x86_64-linux";
      type = "nixos";
      withHomeManager = false;
      extraModules = [ ];
    };
    modules = metadataModules;
  };
in
{
  imports = [
    inputs.flake-file.flakeModules.default
  ];

  flake-file = {
    description = "SwarseFlake - Nix Flake for all SwarselSystems";
    outputs = "inputs: import ./nix/outputs.nix inputs";
    nixConfig = {
      extra-substituters = [
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    inputs = metadata.config.flake-file.inputs // {
      flake-file.url = "github:vic/flake-file";

      flake-parts.url = "github:hercules-ci/flake-parts";
      systems.url = "github:nix-systems/default";

      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
      nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
      nixpkgs-master.url = "github:nixos/nixpkgs/master";
      nixpkgs-kernelpin.url = "github:nixos/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61?narHash=sha256-I45esRSssFtJ8p/gLHUZ1OUaaTaVLluNkABkk6arQwE%3D";
      nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
      nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
      nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
      nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
      nixpkgs-stable25_11.url = "github:NixOS/nixpkgs/nixos-25.11";

      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      nixos-hardware.url = "github:NixOS/nixos-hardware/master";
      nixos-extra-modules.url = "github:oddlama/nixos-extra-modules/main";

      swarsel-nix.url = "github:Swarsel/swarsel-nix/main";
    };
  };
}
