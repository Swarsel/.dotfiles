{
  flake-file.inputs.dns = {
    url = "github:kirelagin/dns.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.dns = { inputs, ... }:
    {
      _module.args.dns = inputs.dns;
    };
}
