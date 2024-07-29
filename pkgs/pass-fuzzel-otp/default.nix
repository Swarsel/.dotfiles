{ writeShellApplication, libnotify, pass, fuzzel, wtype }:

writeShellApplication {
  name = "pass-fuzzel-otp";
  runtimeInputs = [ fuzzel (pass.withExtensions (exts: [ exts.pass-otp ])) ];
  text = builtins.readFile ../../scripts/pass-fuzzel-otp.sh;
}
