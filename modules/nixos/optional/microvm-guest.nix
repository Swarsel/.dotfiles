{ lib, config, ... }:
{
  options.swarselmodules.optional.microvmGuest = lib.mkEnableOption "optional microvmGuest settings";
  # imports = [
  #   inputs.microvm.nixosModules.microvm
  #   "${self}/profiles/nixos"
  #   "${self}/modules/nixos"
  # ];
  config = lib.mkIf config.swarselmodules.optional.microvmGuest
    { };
}
