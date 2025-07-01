{ lib, ... }:
let
  # Try to access the extra builtin we loaded via nix-plugins.
  # Throw an error if that doesn't exist.
  sopsImportEncrypted =
    assert lib.assertMsg (builtins ? extraBuiltins.sopsImportEncrypted)
      "The extra builtin 'sopsImportEncrypted' is not available, so repo.secrets cannot be decrypted. Did you forget to add nix-plugins and point it to `./nix/extra-builtins.nix` ?";
    builtins.extraBuiltins.sopsImportEncrypted;
in

{
  imports = [
    (sopsImportEncrypted ../secrets/repo/globals.nix.enc)
  ];

}
