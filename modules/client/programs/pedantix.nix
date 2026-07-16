{
  flake.modules.homeManager.pedantix =
    {
      self,
      inputs,
      lib,
      ...
    }:
    {
      imports = lib.optionals (inputs ? pedantix && inputs.pedantix ? homeModules) [
        inputs.pedantix.homeModules.default
        {
          swarselsystems.enabledHomeModules = [ "pedantix" ];
          programs.pedantix = {
            enable = true;
            settings = import "${self}/files/nix/pedantix-settings.nix";
          };
        }
      ];
    };
}
