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
        "The file to decrypt must be given as a path to prevent impurity.";
      assert assertMsg (hasSuffix ".nix.age" nixFile)
        "The content of the decrypted file must be a nix expression and should therefore end in .nix.age";
      exec [
        ./sops-decrypt-and-cache.sh
        nixFile
      ];
}
