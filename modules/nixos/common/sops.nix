{ self, config, lib, ... }:
let
  certsSopsFile = self + /secrets/certs/secrets.yaml;
  inherit (config.swarselsystems) mainUser homeDir;
in
{
  options.swarselsystems.modules.commonSops = lib.mkEnableOption "sops config";
  config = lib.mkIf config.swarselsystems.modules.commonSops {
    sops = lib.mkIf (!config.swarselsystems.isPublic) {

      age.sshKeyPaths = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs [ "/persist/.ssh/sops" "/persist/.ssh/ssh_host_ed25519_key" ] [ "${homeDir}/.ssh/sops" "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs "/persist/.dotfiles/secrets/general/secrets.yaml" "${homeDir}/.dotfiles/secrets/general/secrets.yaml";

      validateSopsFiles = false;

      secrets = {
        ernest = { };
        frauns = { };
        hotspot = { };
        eduid = { };
        edupass = { };
        handyhotspot = { };
        vpnuser = { };
        vpnpass = { };
        wireguardpriv = { };
        wireguardpub = { };
        wireguardendpoint = { };
        stashuser = { };
        stashpass = { };
        githubforgeuser = { };
        githubforgepass = { };
        gitlabforgeuser = { };
        gitlabforgepass = { };
        "sweden-aes-128-cbc-udp-dns-crl-verify.pem" = { sopsFile = certsSopsFile; owner = mainUser; };
        "sweden-aes-128-cbc-udp-dns-ca.pem" = { sopsFile = certsSopsFile; owner = mainUser; };
      };
      templates = {
        "network-manager.env".content = ''
          ERNEST=${config.sops.placeholder.ernest}
          FRAUNS=${config.sops.placeholder.frauns}
          HOTSPOT=${config.sops.placeholder.hotspot}
          EDUID=${config.sops.placeholder.eduid}
          EDUPASS=${config.sops.placeholder.edupass}
          HANDYHOTSPOT=${config.sops.placeholder.handyhotspot}
          VPNUSER=${config.sops.placeholder.vpnuser}
          VPNPASS=${config.sops.placeholder.vpnpass}
          WIREGUARDPRIV=${config.sops.placeholder.wireguardpriv}
          WIREGUARDPUB=${config.sops.placeholder.wireguardpub}
          WIREGUARDENDPOINT=${config.sops.placeholder.wireguardendpoint}
        '';
      };
    };
  };
}
