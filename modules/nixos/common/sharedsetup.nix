{ lib, ... }:
{
  options = {
    swarselsystems = {
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

      isImpermanence = lib.mkEnableOption "use impermanence on this system";
      isSecureBoot = lib.mkEnableOption "use secure boot on this system";
    };
  };
}
