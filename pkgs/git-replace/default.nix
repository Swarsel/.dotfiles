{ name, writeShellApplication, git, gnugrep, findutils, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ git gnugrep findutils ];
  text = ''
    git grep -l "$1" | xargs sed -i "s/$1/$2/g"
  '';
}
