{ inputs, ... }: {
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: _prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # river = prev.river.overrideAttrs (oldAttrs: rec {
    #   pname = "river";
    #   version = "git";
    #   src = prev.fetchFromGitHub {
    #     owner = "riverwm";
    #     repo = pname;
    #     rev = "c16628c7f57c51d50f2d10a96c265fb0afaddb02";
    #     hash = "sha256-E3Xtv7JeCmafiNmpuS5VuLgh1TDAbibPtMo6A9Pz6EQ=";
    #     fetchSubmodules = true;
    #   };
    # });
  };

  nixpkgs-stable = final: _prev: {
    stable = import inputs.nixpkgs-stable { inherit (final) system; };
  };
}
