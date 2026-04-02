{ lib, ... }:
let
  # If the given expression is a bare set, it will be wrapped in a function,
  # so that the imported file can always be applied to the inputs, similar to
  # how modules can be functions or sets.
  constSet = x: if builtins.isAttrs x then (_: x) else x;

  sopsImportEncrypted =
    assert lib.assertMsg (builtins ? extraBuiltins.sopsImportEncrypted)
      "The extra builtin 'sopsImportEncrypted' is not available, so repo.secrets cannot be decrypted. Did you forget to add nix-plugins and point it to `<flakeRoot>/files/nix/extra-builtins.nix` ?";
    builtins.extraBuiltins.sopsImportEncrypted;

  importEncrypted =
    path:
    constSet (
      if builtins.pathExists path then
        sopsImportEncrypted path
      else
        { }
    );
in
{
  den = {
    schema.conf = { config, inputs, lib, homeLib, nodes, globals, ... }: {
      options = {
        repo = {
          secretFiles = lib.mkOption {
            default = { };
            type = lib.types.attrsOf lib.types.path;
            example = lib.literalExpression "{ local = ./pii.nix.enc; }";
            description = ''
              This is for storing PII.
                Each path given here must be an sops-encrypted .nix file. For each attribute `<name>`,
                the corresponding file will be decrypted, imported and exposed as {option}`repo.secrets.<name>`.
            '';
          };

          secrets = lib.mkOption {
            readOnly = true;
            default = lib.mapAttrs (_: x: importEncrypted x { inherit lib homeLib nodes globals inputs config; inherit (inputs.topologyPrivate) topologyPrivate; }) config.repo.secretFiles;
            type = lib.types.unspecified;
            description = "Exposes the loaded repo secrets.";
          };
        };
      };
      config = {
        repo.secretFiles =
          let
            local = config.node.secretsDir + "/pii.nix.enc";
          in
          (lib.optionalAttrs (lib.pathExists local) { inherit local; }) // {
            common = ../secrets/repo/pii.nix.enc;
          };
      };
    };
  };
}
