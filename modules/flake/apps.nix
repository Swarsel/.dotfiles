{ self, ... }:
{
  perSystem =
    { system, ... }:
    let
      bootstrap = {
        program = "${self.packages.${system}.swarsel-bootstrap}/bin/swarsel-bootstrap";
        type = "app";
        meta.description = "Custom app swarsel-bootstrap.";
      };
    in
    {
      apps = {
        default = bootstrap;
        swarsel-bootstrap = bootstrap;
      };
    };
}
