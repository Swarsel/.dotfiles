{
  flake.modules.homeManager.glide = {
    programs.glide-browser.config = ''
      glide.keymaps.set("normal", "/", () => glide.findbar.open({ query: "" }));
      glide.keymaps.set("normal", "?", () => glide.findbar.open({ query: "" }));
      glide.keymaps.set("normal", "n", () => glide.findbar.next_match());
      glide.keymaps.set("normal", "N", () => glide.findbar.previous_match());

      function enforce_input_mode() {
        if (glide.ctx.mode !== "normal") {
          return;
        }
        if (glide.commandline.is_active()) {
          void glide.excmds.execute("mode_change command");
        } else if (glide.findbar.is_focused()) {
          void glide.excmds.execute("mode_change insert");
        }
      }

      glide.autocmds.create("ModeChanged", "*:normal", enforce_input_mode);
      setInterval(enforce_input_mode, 100);

      glide.keymaps.set(["insert", "normal"], "<Esc>", () => {
        if (glide.findbar.is_open()) {
          void glide.findbar.close();
        }
        void glide.excmds.execute("mode_change normal");
      });

      glide.keymaps.set("command", "<Esc>", () => void glide.commandline.close());

      async function tab_or_tabopen(query: string) {
        const url = query.includes("://") ? query : `https://''${query}`;
        const tabs = await browser.tabs.query({ currentWindow: true });
        const existing = tabs.find((t) => t.url != null && t.url.includes(query));
        if (existing?.id != null) {
          await browser.tabs.update(existing.id, { active: true });
        } else {
          await browser.tabs.create({ url, cookieStoreId: "firefox-default" });
        }
      }
    '';
  };
}
