{ self, name, writeShellApplication, libnotify, pass, fuzzel, wtype }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ libnotify (pass.withExtensions (exts: [ exts.pass-otp ])) fuzzel wtype ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
