{
  name,
  self,
  stdenv,
  writeShellApplication,
  ...
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [ self.packages.${stdenv.hostPlatform.system}.sync-org-from-files ];
  text = ''
    output="$(sync-org-from-files --dry-run "$@")"
    echo "$output"
    updated="$(echo "$output" | sed -n 's/^  Updated:[[:space:]]*\([0-9]\+\)$/\1/p')"
    if [[ ''${updated:-0} -ne 0 ]]; then
        echo
        echo "org file is out of sync with $updated tangled file(s); run sync-org-from-files and stage SwarselSystems.org."
        exit 1
    fi
  '';
}
