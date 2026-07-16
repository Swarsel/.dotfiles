{
  self,
  lib,
  pkgs,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.navidrome
    self.modules.nixos.spotifyd
    self.modules.nixos.mpd
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  environment.persistence."/state".directories = [
    {
      directory = "/var/lib/alsa";
      group = "root";
      user = "root";
    }
  ];
  microvm = {
    devices = [
      {
        bus = "pci";
        path = "0000:04:04.0";
      }
    ];
    mem = 1024 * 4;
    qemu.machine = "q35";
    vcpu = 2;
  };
  systemd.services.audio-mixer-init = {
    after = [ "sound.target" ];
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset 'Analog Output' Multichannel
    '';
    serviceConfig = {
      RemainAfterExit = true;
      Type = "oneshot";
    };
    wantedBy = [ "sound.target" ];
  };

}
