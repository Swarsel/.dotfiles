{
  flake.modules.nixos.sandbox-access =
    { self, root, ... }:
    {
      sops.secrets.sandbox-wildcard-key.sopsFile = self + /secrets/general/sandbox.yaml;
      networking.hosts."127.0.0.1" =
        builtins.attrValues (import "${self}/hosts/utility/vacanthouse/secrets/pii.nix").services.domains;
      security.pki.certificateFiles = [
        (root "files/public/certs/ca.crt")
      ];
    };
}
