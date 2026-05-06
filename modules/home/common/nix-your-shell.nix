_:
let
  moduleName = "nix-your-shell";
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "nix-your-shell" ];
    programs.${moduleName} = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
