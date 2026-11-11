{
  flake.modules.homeManager.nix-your-shell.config = {
    swarselsystems.enabledHomeModules = [ "nix-your-shell" ];
    programs.nix-your-shell = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
