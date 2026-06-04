{ inputs, lib, ... }:
{
  flake-file.inputs.dns = {
    url = "github:kirelagin/dns.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optionals (inputs ? dns) [
    { _module.args.dns = inputs.dns; }
  ];
}
