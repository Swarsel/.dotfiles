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
          id = "SEH2NMT-IVRQUU5-VPW2HUQ-3GQYDBF-F6H6OY6-X3DZTUZ-LCRE2DJ-QNIXIQ2";
        };
        "sync (@oracle)" = {
          id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
        };
        "server1" = {
          id = "ZXWVC4X-IIARITZ-MERZPHN-HD55Y6G-QJM2GTB-6BWYXMR-DTO3TS2-QDBREQQ";
        };
      };
      folders = {
        "Default Folder" = {
          path = "/home/swarsel/Sync";
          devices = [ "sync (@oracle)" "magicant" ];
          id = "default";
        };
        "Obsidian" = {
          path = "/home/swarsel/Nextcloud/Obsidian";
          devices = [ "sync (@oracle)" "magicant" ];
          id = "yjvni-9eaa7";
        };
        "Org" = {
          path = "/home/swarsel/Nextcloud/Org";
          devices = [ "sync (@oracle)" "magicant" ];
          id = "a7xnl-zjj3d";
        };
        "Vpn" = {
          path = "/home/swarsel/Vpn";
          devices = [ "sync (@oracle)" "magicant" ];
          id = "hgp9s-fyq3p";
        };
      };
    };
  };
}
