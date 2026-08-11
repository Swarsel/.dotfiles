{ root, ... }:
{
  flake.templates =
    let
      mkTemplates =
        names:
        builtins.listToAttrs (
          map (name: {
            inherit name;
            value = {
              description = "${name} project ";
              path = root "files/templates/${name}";
            };
          }) names
        );
      templateNames = [
        "python"
        "rust"
        "go"
        "cpp"
        "latex"
        "default"
      ];
    in
    mkTemplates templateNames;
}
