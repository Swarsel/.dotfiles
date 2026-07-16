{
  flake.modules.nixos.sandbox-access =
    { self, ... }:
    {
      networking.hosts."127.0.0.1" =
        builtins.attrValues (import "${self}/hosts/utility/vacanthouse/secrets/pii.nix").services.domains;

      security.pki.certificateFiles = [
        "${self}/files/public/certs/ca.crt"
      ];
    };
}
