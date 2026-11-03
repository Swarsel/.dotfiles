{
  flake-file.inputs.hint-selectors = {
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      pedantix.follows = "pedantix";
      systems.follows = "systems";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:Swarsel/hint-selectors";
  };

  flake.modules.homeManager.glide =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      programs.glide-browser.config = ''
        glide.autocmds.create("UrlEnter", /https?:\/\/www\.google\.com/, () => {
          glide.buf.keymaps.set("normal", "gi", async () => {
            await glide.excmds.execute("focusinput last");
            await glide.excmds.execute("caret_move endline");
          });
        });
      ''
      + lib.optionalString (inputs ? hint-selectors) ''
        glide.include("hint-selectors.glide.ts").then(() =>
          glide.g.hint_selectors!.setup({
            keys: { primary: "c" },
            hint: start_hints,
            extra: {
              "vbc.atlassian.net": [
                {
                  match: ["*://vbc.atlassian.net/wiki*"],
                  sets: {
                    primary: `[class="_1reo15vq _18m915vq _1bto1l2s _kqswh2mm _o5721q9c _syaz1fxt"], [class="_11c81ixg _1reo15vq _18m915vq _18s81b66 _kqswh2mm _k48p1wq8 _o5721q9c _1bto1l2s _u5f31b66"], [class="_1r04ze3t _kqswstnw"], [class="css-a61etj"], [class="jira-macro-table-underline-pdfexport"]`,
                  },
                },
              ],
            },
          }),
        );
      '';
      xdg.configFile = lib.mkIf (inputs ? hint-selectors) {
        "glide/hint-selectors.glide.ts".source =
          inputs.hint-selectors.packages.${pkgs.stdenv.hostPlatform.system}.glide-integration;
      };
    };
}
