_:
{
  services.syncthing = {
    enable = true;
    user = "swarsel";
    dataDir = "/home/swarsel";
    configDir = "/home/swarsel/.config/syncthing";
    openDefaultPorts = true;
    settings = {
      devices = {
        "magicant" = {
          id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
        };
        "sync (@oracle)" = {
          id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
        };
        "winters" = {
          id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
        };
      };
      folders = {
        "Default Folder" = {
          path = "/home/swarsel/Sync";
          devices = [ "sync (@oracle)" "magicant" "winters" ];
          id = "default";
        };
        "Obsidian" = {
          path = "/home/swarsel/Nextcloud/Obsidian";
          devices = [ "sync (@oracle)" "magicant" "winters" ];
          id = "yjvni-9eaa7";
        };
        "Org" = {
          path = "/home/swarsel/Nextcloud/Org";
          devices = [ "sync (@oracle)" "magicant" "winters" ];
          id = "a7xnl-zjj3d";
        };
        "Vpn" = {
          path = "/home/swarsel/Vpn";
          devices = [ "sync (@oracle)" "magicant" "winters" ];
          id = "hgp9s-fyq3p";
        };
        ".elfeed" = {
          path = "/home/swarsel/.elfeed";
          devices = [ "sync (@oracle)" "magicant" "winters" ];
          id = "h7xbs-fs9v1";
        };
      };
    };
  };
}
