{
  flake.modules.nixos.sandbox-access =
    { self, root, ... }:
    {
      networking.hosts."127.0.0.1" =
        builtins.attrValues (import "${self}/hosts/utility/vacanthouse/secrets/pii.nix").services.domains;

      security.pki.certificateFiles = [
        (root "files/public/certs/ca.crt")
      ];
    };
}
