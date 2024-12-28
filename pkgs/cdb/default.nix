{ writeShellApplication, fzf, ... }:

writeShellApplication {
  name = "cdb";
  runtimeInputs = [ fzf ];
  text = ''
    git checkout "$(git branch --list | grep -v "^\*" | fzf | awk '{print $1}')"
  '';
}
