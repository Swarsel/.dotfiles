{ self, pkgs, lib, config, ... }:
let
  ssh-restrict = "restrict,pty,command=\"${wrapper-dispatch-ssh-nix}/bin/wrapper-dispatch-ssh-nix\" ";

  wrapper-dispatch-ssh-nix = pkgs.writeShellScriptBin "wrapper-dispatch-ssh-nix" ''
    case $SSH_ORIGINAL_COMMAND in
      "nix-daemon --stdio")
        exec env NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${config.nix.package}/bin/nix-daemon --stdio
        ;;
      "nix-store --serve --write")
        exec env NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${config.nix.package}/bin/nix-store --serve --write
        ;;
      *)
        echo "Access only allowed for using the nix remote builder" 1>&2
        exit
    esac
  '';
in
{
  options.swarselmodules.server.ssh-builder = lib.mkEnableOption "enable ssh-builder config on server";
  config = lib.mkIf config.swarselmodules.server.ssh-builder {
    users = {
      groups.builder = { };
      users.builder = {
        useDefaultShell = true;
        isSystemUser = true;
        group = "builder";
        openssh.authorizedKeys.keys = [
          ''${ssh-restrict} ${builtins.readFile "${self}/secrets/public/ssh/builder.pub"}''
        ];
      };
    };

  };
}
