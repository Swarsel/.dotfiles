# largely based on https://github.com/oddlama/nix-config/blob/main/modules/secrets.nix
{ config, inputs, lib, ... }:
let

  # If the given expression is a bare set, it will be wrapped in a function,
  # so that the imported file can always be applied to the inputs, similar to
  # how modules can be functions or sets.
  constSet = x: if builtins.isAttrs x then (_: x) else x;

  # Try to access the extra builtin we loaded via nix-plugins.
  # Throw an error if that doesn't exist.
  sopsImportEncrypted =
    assert lib.assertMsg (builtins ? extraBuiltins.sopsImportEncrypted)
      "The extra builtin 'sopsImportEncrypted' is not available, so repo.secrets cannot be decrypted. Did you forget to add nix-plugins and point it to `<flakeRoot>/nix/extra-builtins.nix` ?";
    builtins.extraBuiltins.sopsImportEncrypted;

  # This "imports" an encrypted .nix.age file by evaluating the decrypted content.
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
  options = {
    repo = {
      secretFiles = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.path;
        example = lib.literalExpression "{ local = ./pii.nix.enc; }";
        description = ''
          This file manages the origin for this machine's repository-secrets. Anything that is
          technically not a secret in the classical sense (i.e. that it has to be protected
          after it has been deployed), but something you want to keep secret from the public;
          Anything that you wouldn't want people to see on GitHub, but that can live unencrypted
          on your own devices. Consider it a more ergonomic nix alternative to using git-crypt.

          All of these secrets may (and probably will be) put into the world-readable nix-store
          on the build and target hosts. You'll most likely want to store personally identifiable
          information here, such as:
            - MAC Addreses
            - Static IP addresses
            - Your full name (when configuring your users)
            - Your postal address (when configuring e.g. home-assistant)
            - ...

          Each path given here must be an sops-encrypted .nix file. For each attribute `<name>`,
          the corresponding file will be decrypted, imported and exposed as {option}`repo.secrets.<name>`.
        '';
      };

      secrets = lib.mkOption {
        readOnly = true;
        default = lib.mapAttrs (_: x: importEncrypted x inputs) config.repo.secretFiles;
        type = lib.types.unspecified;
        description = "Exposes the loaded repo secrets. This option is read-only.";
      };
    };
    swarselsystems.modules.pii = lib.mkEnableOption "enable pii management";
  };
  config = lib.mkIf config.swarselsystems.modules.pii {
    repo.secretFiles =
      let
        local = config.node.secretsDir + "/pii.nix.enc";
      in
      (lib.optionalAttrs (lib.pathExists local) { inherit local; }) // {
        common = ../../../secrets/repo/pii.nix.enc;
      };
  };
}
