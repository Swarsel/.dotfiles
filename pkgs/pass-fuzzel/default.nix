{ self, writeShellApplication, libnotify, pass, fuzzel, wtype }:
let
  name = "pass-fuzzel";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ libnotify (pass.withExtensions (exts: [ exts.pass-otp ])) fuzzel wtype ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
