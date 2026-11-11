{
  root,
  inputs,
  config,
  lib,
  pkgs,
  confLib,
  ...
}:
{

  imports = [
    inputs.self.modules.homeManager.profile-base
    inputs.self.modules.homeManager.profile-dgxspark
    inputs.vbc-nix.homeManagerModules.work-remote
  ];

  swarselsystems = {
    homeSopsSecrets = {
      automationhubtoken.rekey.keyPrefix = confLib.static.sharedSecrets.work;
      ucKey.rekey.keyPrefix = confLib.static.sharedSecrets.work;
      vpn-cert = {
        path = "${config.home.homeDirectory}/.config/vpn/vbc.pem";
        rekey.keyPrefix = confLib.static.sharedSecrets.work;
      };
    };
    isLaptop = false;
    wallpaper = root "files/wallpaper/landscape/surfacewp.png";
  };

  sops.secrets =
    lib.genAttrs
      [
        "claude-mcp-env"
        "ontap-mcp-config"
        "openshift-kubeconfig"
        "vcenter-config"
      ]
      (_: {
        rekey.enable = false;
      });

  services = {
    work-remote.enable = true;
    xcape = {
      enable = true;
      mapExpression.Control_L = "Escape";
    };
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
  };

  home.packages = [
    pkgs._1password-cli
    pkgs.attic-client
    pkgs.azure-cli
    pkgs.step-cli
    (config.repo.secrets.work.vpnCli pkgs)
  ];

  nix.settings.max-jobs = lib.mkForce "auto";
  nixpkgs.overlays = [ inputs.vbc-nix.overlays.default ];
  repo.secretFiles.work = ../../../../secrets/work/pii.nix.enc;

}
