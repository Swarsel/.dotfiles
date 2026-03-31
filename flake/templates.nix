{ self, ... }:
{
  flake = _: {
    templates =
      let
        mkTemplates = names: builtins.listToAttrs (map
          (name: {
            inherit name;
            value = {
              path = "${self}/files/templates/${name}";
              description = "${name} project ";
            };
          })
          names);
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
  };
}
