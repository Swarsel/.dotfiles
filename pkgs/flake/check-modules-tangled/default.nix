{
  name,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  writeShellApplication,
  ...
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [
    coreutils
    findutils
    gnugrep
    gnused
  ];
  text = ''
    org="SwarselSystems.org"

    on_disk="$(find modules -type f | sort -u)"
    tangled="$(grep -oE ':tangle[[:space:]]+(\S+)' "$org" | sed -E 's/:tangle[[:space:]]+//' | grep '^modules/' | sort -u)"

    untracked="$(comm -23 <(echo "$on_disk") <(echo "$tangled"))"

    if [[ -n "$untracked" ]]; then
        echo "The following files under modules/ are not tangled from $org:"
        while IFS= read -r file; do
            echo "  $file"
        done <<< "$untracked"
        echo
        echo "Add a source block with :tangle <path> for each, or remove the file."
        exit 1
    fi
  '';
}
