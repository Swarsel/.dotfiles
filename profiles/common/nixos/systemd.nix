{ ... }:
{
  # systemd
  systemd.extraConfig = ''
    DefaultTimeoutStartSec=60s
    DefaultTimeoutStopSec=15s
  '';
}
