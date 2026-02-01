{ lib, config, ... }:
{
  options.swarselprofiles.dgxspark = lib.mkEnableOption "is this a dgx spark host";
  config = lib.mkIf config.swarselprofiles.dgxspark {
    swarselmodules = {
      atuin = lib.mkDefault true;
      bash = lib.mkDefault true;
      blueman-applet = lib.mkDefault true;
      direnv = lib.mkDefault true;
      eza = lib.mkDefault true;
      firefox = lib.mkDefault true;
      fuzzel = lib.mkDefault true;
      general = lib.mkDefault true;
      git = lib.mkDefault true;
      gpgagent = lib.mkDefault true;
      kitty = lib.mkDefault true;
      nix-index = lib.mkDefault true;
      nixgl = lib.mkDefault true;
      nix-your-shell = lib.mkDefault true;
      nm-applet = lib.mkDefault true;
      sops = lib.mkDefault true;
      starship = lib.mkDefault true;
      stylix = lib.mkDefault true;
      tmux = lib.mkDefault true;
      zellij = lib.mkDefault true;
      zsh = lib.mkDefault true;
    };
  };

}
