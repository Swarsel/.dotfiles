{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pass-fuzzel
    cura5
    cdw
    cdb
    bak
    timer
    e
    swarselcheck
    waybarupdate
    opacitytoggle
    fs-diff
    update-checker
    github-notifications
    screenshare
    hm-specialisation
    t2ts
    ts2t
    vershell
    eontimer

    bootstrap

    (pkgs.writeScriptBin "project" ''
      #! ${pkgs.bash}/bin/bash
      if [ "$1" == "rust" ]; then
      cp ~/.dotfiles/templates/rust_flake.nix ./flake.nix
      cp ~/.dotfiles/templates/toolchain.toml .
      elif [ "$1" == "cpp" ]; then
      cp ~/.dotfiles/templates/cpp_flake.nix ./flake.nix
      elif [ "$1" == "python" ]; then
      cp ~/.dotfiles/templates/py_flake.nix ./flake.nix
      elif [ "$1" == "cuda" ]; then
      cp ~/.dotfiles/templates/cu_flake.nix ./flake.nix
      elif [ "$1" == "other" ]; then
      cp ~/.dotfiles/templates/other_flake.nix ./flake.nix
      elif [ "$1" == "latex" ]; then
        if [ "$2" == "" ]; then
        echo "No filename specified, usage: 'project latex <NAME>'"
        exit 0
        fi
      cp ~/.dotfiles/templates/tex_standard.tex ./"$2".tex
      exit 0
      else
      echo "No valid argument given. Valid arguments are rust cpp python, cuda"
      exit 0
      fi
      echo "use flake" >> .envrc
      direnv allow
    '')






  ];
}
