{ config, lib, ... }:
let
  fmods = config.flake.modules;
in
{
  flake.modules = {
    homeManager.gaming =
      {
        pkgs,
        confLib,
        nixosConfig ? null,
        ...
      }:
      {
        config = {
          programs.lutris = {
            enable = true;
            extraPackages = with pkgs; [
              winetricks
              gamescope
              umu-launcher
            ];
            protonPackages = with pkgs; [
              proton-ge-bin
            ];
            steamPackage = if nixosConfig != null then confLib.getConfig.programs.steam.package else pkgs.steam;
            winePackages = with pkgs; [
              wineWow64Packages.waylandFull
            ];
          };
          # specialisation = {
          #   gaming.configuration = {
          home.packages = with pkgs; [
            # lutris
            wine
            protonplus
            winetricks
            dwarfs
            fuse-overlayfs
            # steam
            steam-run
            patchelf
            gamescope
            vulkan-tools
            (symlinkJoin {
              buildInputs = [ makeWrapper ];
              name = "moonlight-qt";
              paths = [ moonlight-qt ];
              postBuild = ''
                wrapProgram $out/bin/moonlight \
                  --set-default SDL_MOUSE_RELATIVE_SYSTEM_SCALE 1
              '';
            })
            ns-usbloader

            quark-goldleaf

            # gog games installing
            heroic

            # minecraft
            prismlauncher # has overrides
            temurin-bin-17

            retroarch
          ];
          #   };
          # };
        };
      };
    nixos.gaming =
      {
        config,
        pkgs,
        withHomeManager,
        ...
      }:
      lib.mkMerge [
        {
          programs.steam = {
            enable = true;
            package = pkgs.steam;
            extraCompatPackages = [
              pkgs.proton-ge-bin
            ];
          };
        }
        (lib.mkIf withHomeManager {
          home-manager.users."${config.swarselsystems.mainUser}".imports = [
            fmods.homeManager.gaming
          ];
        })
      ];
  };
}
