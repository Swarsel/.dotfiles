{ inputs, lib, ... }:
{
  flake-file.inputs.sops.url = "github:Mic92/sops-nix";

  imports = lib.optionals (inputs ? sops) [
    inputs.sops.nixosModules.sops
    ({ self, config, ... }: {
      sops = {

        # age.sshKeyPaths = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs [ "/persist/.ssh/sops" "/persist/.ssh/ssh_host_ed25519_key" ] [ "${config.swarselsystems.homeDir}/.ssh/sops" "/etc/ssh/sops" "/etc/ssh/ssh_host_ed25519_key" ];
        age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}/etc/ssh/ssh_host_ed25519_key" ];
        # defaultSopsFile = "${if config.swarselsystems.isImpermanence then "/persist" else ""}${config.swarselsystems.flakePath}/secrets/repo/common.yaml";
        defaultSopsFile = self + "/secrets/repo/common.yaml";

        validateSopsFiles = false;

      };
    })
  ];
}
