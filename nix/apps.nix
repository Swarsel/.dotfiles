{ self, ... }:
{
  perSystem = { system, ... }:
    let
      mkApps = system: names: self: builtins.listToAttrs (map
        (name: {
          inherit name;
          value = {
            type = "app";
            program = "${self.packages.${system}.${name}}/bin/${name}";
            meta = {
              description = "Custom app ${name}.";
            };
          };
        })
        names);

      appNames = [
        "swarsel-bootstrap"
        "swarsel-install"
        "swarsel-rebuild"
        "swarsel-postinstall"
      ];

      appSet = mkApps system appNames self;
    in
    {
      apps = appSet // {
        default = appSet.swarsel-bootstrap;
      };
    };
}
