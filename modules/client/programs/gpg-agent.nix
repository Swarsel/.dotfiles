{
  flake.modules.homeManager.gpg-agent =
    {
      self,
      config,
      lib,
      pkgs,
      options,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir mainUser;
      withYubikeyAgent = false;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "gpgagent" ];
        # we need the normal ssh agent for cert based login as well as support for sk keys, both of which are not present for gpg-agent
        services = {
          ssh-agent.enable = true;
          yubikey-agent.enable = false; # we use it but do not want the SSH_AUTH_SOCK set
        };
        services.gpg-agent = {
          enable = true;
          # pinentry.package = pkgs.pinentry.gtk2;
          defaultCacheTtl = 600;
          enableExtraSocket = true;
          enableScDaemon = true;
          enableSshSupport = false; # so that the SSH_AUTH_SOCK can still default to ssh-agent. however we want the capability of doing gpg ssh logins, hence the extraConfig
          enableZshIntegration = true;
          extraConfig = ''
            enable-ssh-support
              allow-loopback-pinentry
              allow-emacs-pinentry
          '';
          maxCacheTtl = 7200;
          pinentry = {
            package = pkgs.wayprompt;
            program = "pinentry-wayprompt";
          };
          sshKeys = [
            "4BE7925262289B476DBBC17B76FD3810215AE097"
          ];
          verbose = true;
        };
        programs.gpg = {
          enable = true;
          publicKeys = [
            {
              source = "${self}/files/public/gpg/gpg-public-key-0x76FD3810215AE097.asc";
              trust = 5;
            }
          ];
          scdaemonSettings = {
            disable-ccid = true; # prevent conflicts between pcscd and scdameon
            # pcsc-shared = true; # as long as only one key is used, this prevents key from not being detected sometimes
          };
        };
        home.packages = [
          (lib.mkIf withYubikeyAgent config.services.yubikey-agent.package)
        ];
        systemd.user = {
          services.yubikey-agent = lib.mkIf withYubikeyAgent {
            Service = {
              ExecStart = "${config.services.yubikey-agent.package}/bin/yubikey-agent -l %t/yubikey-agent/yubikey-agent.sock";
              ReadWritePaths = [ "%t" ];
              Type = "simple";
            };
            Unit = {
              After = "yubikey-agent.socket";
              Description = "Seamless ssh-agent for YubiKeys";
              Documentation = "https://github.com/FiloSottile/yubikey-agent";
              RefuseManualStart = true;
              Requires = "yubikey-agent.socket";
            };
          };

          sockets = {
            gpg-agent-ssh =
              let
                inherit (config.programs.gpg) homedir;
                # Act like `xxd -r -p | base32` but with z-base-32 alphabet and no trailing padding.
                # Written in Nix for purity.
                hexStringToBase32 =
                  let
                    mod = a: b: a - a / b * b;
                    pow2 = lib.elemAt [
                      1
                      2
                      4
                      8
                      16
                      32
                      64
                      128
                      256
                    ];

                    base32Alphabet = lib.stringToCharacters "ybndrfg8ejkmcpqxot1uwisza345h769";
                    hexToIntTable = lib.listToAttrs (
                      lib.genList (x: {
                        name = lib.toLower (lib.toHexString x);
                        value = x;
                      }) 16
                    );

                    initState = {
                      buf = 0;
                      bufBits = 0;
                      ret = "";
                    };
                    go =
                      {
                        buf,
                        bufBits,
                        ret,
                      }:
                      hex:
                      let
                        buf' = buf * pow2 4 + hexToIntTable.${hex};
                        bufBits' = bufBits + 4;
                        extraBits = bufBits' - 5;
                      in
                      if bufBits >= 5 then
                        {
                          buf = mod buf' (pow2 extraBits);
                          bufBits = bufBits' - 5;
                          ret = ret + lib.elemAt base32Alphabet (buf' / pow2 extraBits);
                        }
                      else
                        {
                          inherit ret;
                          buf = buf';
                          bufBits = bufBits';
                        };
                  in
                  hexString: (lib.foldl' go initState (lib.stringToCharacters hexString)).ret;
                gpgconf =
                  dir:
                  let
                    hash = lib.substring 0 24 (hexStringToBase32 (builtins.hashString "sha1" homedir));
                    subdir = if homedir == options.programs.gpg.homedir.default then "${dir}" else "d.${hash}/${dir}";
                  in
                  "%t/gnupg/${subdir}";
              in
              {
                Install.WantedBy = [ "sockets.target" ];
                Socket = {
                  DirectoryMode = "0700";
                  FileDescriptorName = "ssh";
                  ListenStream = gpgconf "S.gpg-agent.ssh";
                  Service = "gpg-agent.service";
                  SocketMode = "0600";
                };
                Unit = {
                  Description = "GnuPG cryptographic agent (ssh-agent emulation)";
                  Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
                };
              };
            yubikey-agent = lib.mkIf withYubikeyAgent {
              Install.WantedBy = [ "sockets.target" ];
              Socket = {
                DirectoryMode = "0700";
                ListenStream = "%t/yubikey-agent/yubikey-agent.sock";
                RuntimeDirectory = "yubikey-agent";
                SocketMode = "0600";
              };
              Unit = {
                Description = "Unix domain socket for Yubikey SSH agent";
                Documentation = "https://github.com/FiloSottile/yubikey-agent";
              };
            };
          };

          tmpfiles.rules = [
            "d ${homeDir}/.gnupg 0700 ${mainUser} users - -"
          ];
        };
        # assure correct permissions
        # systemd.user.tmpfiles.settings."30-gpgagent".rules = {
        #   "${homeDir}/.gnupg" = {
        #     d = {
        #       group = "users";
        #       user = mainUser;
        #       mode = "0700";
        #     };
        #   };
        # };
      };
    };
}
