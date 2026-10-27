{
  name,
  e2fsprogs,
  systemd,
  writeShellApplication,
  ...
}:
let
  efiVariable = "SwarselDegraded-93933e1c-d7df-47ca-9af3-e98f6553ca3c";
in
writeShellApplication {
  inherit name;
  passthru = { inherit efiVariable; };
  runtimeInputs = [
    e2fsprogs
    systemd
  ];
  text = ''
    variable=/sys/firmware/efi/efivars/${efiVariable}
    if [ -e "$variable" ]; then
      chattr -i "$variable"
    fi
    printf '\x07\x00\x00\x00\x01' > "$variable"
    systemctl reboot
  '';
}
