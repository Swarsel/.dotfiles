{ lib, ... }:
{
  options.swarselsystems.user = lib.mkOption {
    type = lib.types.str;
    default = "swarsel";
  };
  options.swarselsystems.withHomeManager = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
  options.swarselsystems.isSwap = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
  options.swarselsystems.swapSize = lib.mkOption {
    type = lib.types.str;
    default = "8G";
  };
  options.swarselsystems.rootDisk = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
  options.swarselsystems.isCrypted = lib.mkEnableOption "uses full disk encryption";
  options.swarselsystems.initialSetup = lib.mkEnableOption "initial setup (no sops keys available)";

  options.swarselsystems.isImpermanence = lib.mkEnableOption "use impermanence on this system";
  options.swarselsystems.isSecureBoot = lib.mkEnableOption "use secure boot on this system";
}
