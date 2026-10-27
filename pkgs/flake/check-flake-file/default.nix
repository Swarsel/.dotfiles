{
  name,
  stdenv,
  writeShellApplication,
  ...
}:

writeShellApplication {
  inherit name;
  text = ''
    if [[ -n ''${NIX_BUILD_TOP:-} ]]; then
        exit 0
    fi

    nix build --no-link --print-build-logs ".#checks.${stdenv.hostPlatform.system}.check-flake-file"
  '';
}
