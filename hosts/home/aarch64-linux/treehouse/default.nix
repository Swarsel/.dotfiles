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
      automationhubtoken.sopsFile = inputs.self + /secrets/work/secrets.yaml;
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
    bash.sessionVariables = lib.genAttrs [
      "ANSIBLE_GALAXY_SERVER_COMMUNITY_TOKEN"
      "ANSIBLE_GALAXY_SERVER_PUBLISHED_TOKEN"
      "ANSIBLE_GALAXY_SERVER_RH_CERTIFIED_TOKEN"
      "ANSIBLE_GALAXY_SERVER_STAGING_TOKEN"
    ] (_: "$(cat ${config.sops.secrets.automationhubtoken.path})");
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
