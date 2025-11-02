{ self, outputs, ... }:
{

  imports = [
    # inputs.sops-nix.homeManagerModules.sops
    "${self}/modules/home"
    "${self}/modules/nixos/common/pii.nix"
    "${self}/modules/nixos/common/meta.nix"
  ];

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

  # programs.zsh.initContent = "
  #   export GPG_TTY=\"$(tty)\"
  # export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  # gpgconf --launch gpg-agent
  #       ";

  swarselsystems = {
    isLaptop = false;
    isNixos = false;
    wallpaper = self + /files/wallpaper/surfacewp.png;
  };

  swarselprofiles = {
    dgxspark = true;
  };

}
