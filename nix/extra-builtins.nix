# adapted from https://github.com/oddlama/nix-config/blob/main/nix/extra-builtins.nix
{ exec, ... }:
let
  assertMsg = pred: msg: pred || builtins.throw msg;
  hasSuffix =
    suffix: content:
    let
      lenContent = builtins.stringLength content;
      lenSuffix = builtins.stringLength suffix;
    in
    lenContent >= lenSuffix && builtins.substring (lenContent - lenSuffix) lenContent content == suffix;
in
{
  # Instead of calling sops directly here, we call a wrapper script that will cache the output
  # in a predictable path in /tmp, which allows us to only require the password for each encrypted
  # file once.
  sopsImportEncrypted =
    nixFile:
      assert assertMsg (builtins.isPath nixFile)
        "The file to decrypt must be given as a path (not a string) to prevent impurity.";
      assert assertMsg (hasSuffix ".nix.enc" nixFile)
        "The content of the decrypted file must be a nix expression and should therefore end in .nix.enc";
      exec [
        ./sops-decrypt-and-cache.sh
        nixFile
      ];
}
