{
  root,
  name,
  cargo,
  direnv,
  formats,
  git,
  go,
  nix,
  python3,
  runCommand,
  taplo,
  uv,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    cargo
    direnv
    git
    go
    nix
    python3
    uv
  ];
  text = ''
    template=$1
    project=''${2:-$(basename "$PWD")}

    if [[ ! -d .git ]]; then
        git init -q
    fi

    ignore=()
    case $template in
        go)
            go mod init "$project"
            printf 'package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("Hello, World!")\n}\n' > main.go
            ;;
        latex)
            ignore=("*.pdf" "!figures/**/*.pdf" "*.aux" "*.bbl" "*.bcf" "*.blg" "*.fdb_latexmk" "*.fls" "*.log" "*.out" "*.run.xml" "*.synctex.gz" "*.toc" "_minted*/")
            ;;
        python)
            uv init --package --vcs none --no-readme --no-pin-python --name "$project"
            uv add --dev --no-sync debugpy
            ignore=(.venv/ __pycache__/)
            ;;
        rust)
            cargo init --vcs none --name "$project"
            cargo generate-lockfile
            ignore=(/target)
            ;;
    esac

    nix flake init --template "$FLAKE#$template"
    sed -i "s/^  description = \"name\";/  description = \"$project\";/" flake.nix
    printf 'use flake\n' > .envrc
    printf '%s\n' /result .direnv/ .pre-commit-config.yaml "''${ignore[@]}" > .gitignore
    install -m644 ${
      runCommand "pedantix.toml" { nativeBuildInputs = [ taplo ]; } ''
        taplo fmt - < ${
          (formats.toml { }).generate "pedantix.toml" (import (root "files/nix/pedantix-settings.nix"))
        } > $out
      ''
    } pedantix.toml
    git add -A
    direnv allow
  '';
}
