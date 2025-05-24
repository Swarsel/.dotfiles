{ self, inputs, lib, ... }:

let
  additions = final: _: import "${self}/pkgs" { pkgs = final; inherit lib; };

  modifications = final: prev: {
    vesktop = prev.vesktop.override {
      withSystemVencord = true;
    };

    firefox = prev.firefox.override {
      nativeMessagingHosts = [
        prev.tridactyl-native
        prev.browserpass
        prev.plasma5Packages.plasma-browser-integration
      ];
    };

    mgba = final.swarsel-mgba;

    retroarch = prev.retroarch.withCores (cores: with cores; [
      snes9x # snes
      nestopia # nes
      dosbox # dos
      scummvm # scumm
      vba-m # gb/a
      mgba # gb/a
      melonds # ds
      dolphin # gc/wii
    ]);



  };

  nixpkgs-stable = final: _: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  nixpkgs-stable24_05 = final: _: {
    stable24_05 = import inputs.nixpkgs-stable24_05 {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  nixpkgs-stable24_11 = final: _: {
    stable24_11 = import inputs.nixpkgs-stable24_11 {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  zjstatus = _: prev: {
    zjstatus = inputs.zjstatus.packages.${prev.system}.default;
  };

in
{
  default =
    final: prev:

    (additions final prev)
    // (modifications final prev)
    // (nixpkgs-stable final prev)
    // (nixpkgs-stable24_05 final prev)
    // (nixpkgs-stable24_11 final prev)
    // (zjstatus final prev)
    // (inputs.vbc-nix.overlays.default final prev)
    // (inputs.nur.overlays.default final prev)
    // (inputs.emacs-overlay.overlay final prev)
    // (inputs.nix-topology.overlays.default final prev)
    // (inputs.nixgl.overlay final prev);

}
