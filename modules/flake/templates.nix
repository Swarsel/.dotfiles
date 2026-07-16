{ self, ... }:
{
  flake = {
    templates =
      let
        mkTemplates =
          names:
          builtins.listToAttrs (
            map (name: {
              inherit name;
              value = {
                description = "${name} project ";
                path = "${self}/files/templates/${name}";
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
  };
}
