{
  root,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{

  imports = [
    inputs.self.modules.homeManager.profile-base
    inputs.self.modules.homeManager.profile-dgxspark
  ]
  ++ lib.optionals (inputs.vbc-nix ? homeManagerModules) [
    inputs.vbc-nix.homeManagerModules.work-remote
    {
      services.work-remote.enable = true;
      nixpkgs.overlays = [ inputs.vbc-nix.overlays.default ];
    }
  ];

  swarselsystems = {
    homeSopsSecrets = {
      ucKey.sopsFile = inputs.self + /secrets/work/secrets.yaml;
      vpn-cert = {
        path = "${config.home.homeDirectory}/.config/vpn/vbc.pem";
        sopsFile = inputs.self + /secrets/work/secrets.yaml;
      };
    };
    isLaptop = false;
    wallpaper = root "files/wallpaper/landscape/surfacewp.png";
  };

  services.xcape = {
    enable = true;
    mapExpression.Control_L = "Escape";
  };

  programs = {
    git.signing = {
      format = lib.mkForce "ssh";
      key = lib.mkForce "${config.home.homeDirectory}/.ssh/id_rsa.pub";
    };
    openstackclient = {
      enable = true;
      cloudsSettings = {
        inherit (config.repo.secrets.work) clouds;
      };
    };
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = builtins.removeAttrs config.repo.secrets.work.sshConfig [ "*" ];
    };
    tmux.shell = lib.mkForce (lib.getExe pkgs.bash);
    zellij.settings.default_shell = lib.mkForce "bash";
  };

  home.packages = [
    pkgs._1password-cli
    pkgs.attic-client
    pkgs.azure-cli
    pkgs.step-cli
    (config.repo.secrets.work.vpnCli pkgs)
  ];

  nix.settings.max-jobs = lib.mkForce "auto";
  repo.secretFiles.work = ../../../../secrets/work/pii.nix.enc;

}
