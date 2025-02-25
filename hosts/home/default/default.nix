{ self, outputs, config, ... }:
{

  imports = [
    inputs.stylix.homeManagerModules.stylix
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-index-database.hmModules.nix-index
    ./profiles/home/common
  ] ++ (builtins.attrValues outputs.homeModules);

  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  services.xcape = {
    enable = true;
    mapExpression = {
      Control_L = "Escape";
    };
  };

  programs.zsh.initExtra = "
  export GPG_TTY=\"$(tty)\"
  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent
        ";

  swarselsystems = {
    isLaptop = true;
    isNixos = false;
    wallpaper = self + /wallpaper/surfacewp.png;
  };

}
