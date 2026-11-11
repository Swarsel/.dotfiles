{ root, lib, ... }:
{
  flake.templates =
    lib.genAttrs
      [
        "python"
        "rust"
        "go"
        "latex"
        "default"
      ]
      (name: {
        description = "${name} project";
        path = root "files/templates/${name}";
      });
}
