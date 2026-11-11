{
  flake.modules.homeManager.pedantix =
    { root, inputs, ... }:
    {
      imports = [ inputs.pedantix.homeModules.default ];
      swarselsystems.enabledHomeModules = [ "pedantix" ];
      programs.pedantix = {
        enable = true;
        settings = import (root "files/nix/pedantix-settings.nix");
      };
    };
}
