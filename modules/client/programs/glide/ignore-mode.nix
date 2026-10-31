{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    glide.keymaps.set("normal", "<C-Esc>", () => glide.excmds.execute("mode_change ignore"), {
      description: "Enter ignore mode",
    });
    glide.keymaps.set("ignore", "<C-Esc>", () => glide.excmds.execute("mode_change normal"), {
      description: "Leave ignore mode",
    });

    const ignore_mode_sites = [
      /https?:\/\/pokerogue\.net/,
      /https?:\/\/typelit\.io/,
      /https?:\/\/vc-impimba-1\.m\.imp\.ac\.at\/ui\/webconsole/,
    ];

    let ignore_mode_auto = false;
    glide.autocmds.create("UrlEnter", /^/, ({ url }) => {
      if (ignore_mode_sites.some((pattern) => pattern.test(url))) {
        ignore_mode_auto = true;
        void glide.excmds.execute("mode_change ignore");
      } else if (ignore_mode_auto) {
        ignore_mode_auto = false;
        if (glide.ctx.mode === "ignore") {
          void glide.excmds.execute("mode_change normal");
        }
      }
    });
  '';
}
