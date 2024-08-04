{
  laptop = import ./laptop.nix;
  hardware = import ./hardware.nix;
  monitors = import ./monitors.nix;
  input = import ./input.nix;
  nixos = import ./nixos.nix;
  waybar = import ./waybar.nix;
  startup = import ./startup.nix;
  wallpaper = import ./wallpaper.nix;
  filesystem = import ./filesystem.nix;
}
