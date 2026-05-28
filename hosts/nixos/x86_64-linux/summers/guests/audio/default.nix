{ self, lib, pkgs, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/server/navidrome.nix"
    "${self}/modules/nixos/server/spotifyd.nix"
    "${self}/modules/nixos/server/mpd.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 4;
    vcpu = 2;
    qemu.machine = "q35";
    devices = [
      { bus = "pci"; path = "0000:04:04.0"; }
    ];
  };

  environment.persistence."/state".directories = [
    { directory = "/var/lib/alsa"; user = "root"; group = "root"; }
  ];

  systemd.services.audio-mixer-init = {
    wantedBy = [ "sound.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset 'Analog Output' Multichannel
    '';
  };

}
