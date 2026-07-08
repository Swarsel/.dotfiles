{
  flake.modules.homeManager.glide = {
    programs.glide-browser.config = ''
      function add_site_shortcuts(shortcuts: Record<string, string>) {
        for (const [keys, target] of Object.entries(shortcuts)) {
          glide.keymaps.set("normal", keys, () => tab_or_tabopen(target), {
            description: `Focus or open ''${target}`,
          });
        }
      }

      add_site_shortcuts({
        ghp: "https://github.com/pulls",
        ghi: "https://github.com/issues/assigned?q=is%3Aissue%20state%3Aopen%20archived%3Afalse%20(assignee%3A%40me%20OR%20author%3A%40me)%20sort%3Aupdated-desc",
        ghv: "github.com/orgs/vbc-it/repositories",
        ghc: "github.com/orgs/CLIP-HPC/repositories",
        ghd: "github.com/Swarsel/.dotfiles",
        ghni: "github.com/NixOS/nixpkgs/issues",
        ghnp: "github.com/NixOS/nixpkgs/pulls",
        gprn: "www.reddit.com/r/NixOS/",
        gpd: "discourse.nixos.org/",
        gpp: "parkour.wien/categories",
      });
    '';
  };
}
