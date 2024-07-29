{ writeShellApplication, libnotify, pass, fuzzel, wtype }:

writeShellApplication {
  name = "pass-fuzzel";
  runtimeInputs = [ libnotify (pass.withExtensions (exts: [ exts.pass-otp ])) fuzzel wtype ];
  text = builtins.readFile ../../scripts/pass-fuzzel.sh;
}
