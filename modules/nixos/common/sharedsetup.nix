{ lib, ... }:
{
  options.swarselsystems = {
    withHomeManager = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    isSwap = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "8G";
    };
    rootDisk = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    isCrypted = lib.mkEnableOption "uses full disk encryption";
    initialSetup = lib.mkEnableOption "initial setup (no sops keys available)";

    isImpermanence = lib.mkEnableOption "use impermanence on this system";
    isSecureBoot = lib.mkEnableOption "use secure boot on this system";

    globals = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        options = {

          services = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  domain = lib.mkOption {
                    type = lib.types.str;
                    description = "Domain that the service runs under";
                  };
                };
              }
            );
          };
          domains = {
            main = lib.mkOption {
              type = lib.types.str;
              description = "My main domain.";
            };
          };

        };
      };
    };
  };
}
