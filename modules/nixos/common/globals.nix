{ lib, options, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    globals = mkOption {
      default = { };
      type = types.submodule {
        options = {
          user = {
            name = mkOption {
              type = types.str;
            };
            work = mkOption {
              type = types.str;
            };
          };


          services = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {
                  domain = mkOption {
                    type = types.str;
                  };
                };
              }
            );
          };

          domains = {
            main = mkOption {
              type = types.str;
            };
          };
        };
      };
    };

    _globalsDefs = mkOption {
      type = types.unspecified;
      default = options.globals.definitions;
      readOnly = true;
      internal = true;
    };
  };
}
