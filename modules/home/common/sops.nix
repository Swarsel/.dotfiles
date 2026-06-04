{ inputs, lib, type, ... }:
{
  flake-file.inputs.sops = lib.mkDefault { url = "github:Mic92/sops-nix"; };

  imports = lib.optionals (inputs ? sops) [
    inputs.sops.homeManagerModules.sops
    ({ self, config, ... }:
      let
        inherit (config.swarselsystems) homeDir;
      in
      {
        swarselsystems.enabledHomeModules = [ "sops" ];

        sops = lib.mkIf (type != "nixos" && !config.swarselsystems.isNixos) {
          age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}${homeDir}/.ssh/sops" ];
          defaultSopsFile = self + "/secrets/repo/common.yaml";

          validateSopsFiles = false;
        };
      })
  ];
}
