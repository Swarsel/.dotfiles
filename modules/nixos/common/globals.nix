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
          root = {
            hashedPassword = mkOption {
              type = types.str;
              description = "My root user's password hash.";
            };
          };

          myuser = {
            name = mkOption {
              type = types.str;
              description = "My unix username.";
            };
            hashedPassword = mkOption {
              type = types.str;
              description = "My unix password hash.";
            };
          };


          services = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {
                  domain = mkOption {
                    type = types.str;
                    description = "The domain under which this service can be reached";
                  };
                };
              }
            );
          };

          domains = {
            me = mkOption {
              type = types.str;
              description = "My main domain.";
            };

            personal = mkOption {
              type = types.str;
              description = "My personal domain.";
            };
          };

          macs = mkOption {
            default = { };
            type = types.attrsOf types.str;
            description = "Known MAC addresses for external devices.";
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
