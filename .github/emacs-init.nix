modules:
let
  flake = builtins.getFlake (toString ../.);
  inherit (flake.inputs) home-manager nixpkgs nur-expressions;
  pkgs = nixpkgs.legacyPackages.x86_64-linux;

  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      "${nur-expressions}/hm-modules/emacs-init.nix"
      {
        programs.emacs = {
          enable = true;
          init.enable = true;
        };
        home = {
          homeDirectory = "/home/user";
          stateVersion = "25.05";
          username = "user";
        };
      }
    ]
    ++ map (file: (import "${modules}/${file}").flake.modules.homeManager.emacs-init or { }) (
      builtins.attrNames (builtins.readDir modules)
    );
  };

  files = home.config.programs.emacs.extraPackages pkgs.emacsPackages;
in
{
  early-init = (builtins.elemAt files 0).src.text;
  init = (builtins.elemAt files 1).src.text;
}
