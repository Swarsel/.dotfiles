{
  flake.modules.nixos.ssh-builder =
    {
      self,
      config,
      pkgs,
      confLib,
      ...
    }:
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
      config = {
        swarselsystems.enabledServerModules = [ "ssh-builder" ];
        users = {
          users.builder = {
            group = "builder";
            isSystemUser = true;
            openssh.authorizedKeys.keys = [
              "${ssh-restrict} ${builtins.readFile "${self}/files/public/ssh/builder.pub"}"
            ];
            useDefaultShell = true;
          };
          groups.builder = { };
          persistentIds.builder = confLib.mkIds 965;
        };
        services.openssh = {
          settings = {
            AllowUsers = [
              "builder"
            ];
          };
        };

      };
    }

  ;
}
