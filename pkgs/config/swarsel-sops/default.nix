{
  name,
  homeConfig,
  sops,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [ sops ];
  text = ''
    cd ${homeConfig.swarselsystems.flakePath}
    find . -path ./files/public -prune -o -path ./.github -prune -o -path ./secrets/rekeyed -prune -o \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.enc' \) \
      -not -name '.sops.yaml' -not -name 'swarsel.yaml' -not -name '.pre-commit-config.yaml' -print0 |
      xargs --null -I{} sops updatekeys --yes {}
    nix run --builders "" .#sops-rekey -- --add-to-git rekey
  '';
}
