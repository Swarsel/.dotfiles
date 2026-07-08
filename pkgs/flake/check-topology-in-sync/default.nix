{
  name,
  git,
  writeShellApplication,
  ...
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [ git ];
  text = ''
    big="files/topology/topology.png"
    small="files/topology/topology_small.png"

    staged="$(git diff --cached --name-only --diff-filter=ACMR)"

    big_staged=false
    small_staged=false
    while IFS= read -r file; do
        [[ $file == "$big" ]] && big_staged=true
        [[ $file == "$small" ]] && small_staged=true
    done <<< "$staged"

    if [[ $big_staged == true && $small_staged == false ]]; then
        echo "$big changed but $small was not regenerated in this commit."
        exit 1
    fi

    if [[ $small_staged == true && $big_staged == false ]]; then
        echo "$small changed but $big was not updated in this commit."
        exit 1
    fi
  '';
}
