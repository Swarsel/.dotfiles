{
  flake-file.inputs.dns = {
    inputs = {
      flake-utils.follows = "flake-utils";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:kirelagin/dns.nix";
  };

  flake.modules.nixos.dns =
    { inputs, ... }:
    {
      _module.args.dns = inputs.dns;
    };
}
