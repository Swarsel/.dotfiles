{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
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
    glide.autocmds.create("CommandLineExit", enforce_input_mode);
    glide.autocmds.create("ModeChanged", "*:command", () => start_enforce_polling());

    let enforce_timer: ReturnType<typeof setInterval> | null = null;
    function stop_enforce_polling() {
      if (enforce_timer != null) {
        clearInterval(enforce_timer);
        enforce_timer = null;
      }
    }
    function start_enforce_polling() {
      if (enforce_timer != null) {
        return;
      }
      enforce_timer = setInterval(() => {
        if (!glide.findbar.is_open() && !glide.commandline.is_active()) {
          stop_enforce_polling();
          return;
        }
        enforce_input_mode();
      }, 100);
    }

    async function open_findbar() {
      await glide.findbar.open({ query: "" });
      start_enforce_polling();
    }

    glide.keymaps.set("normal", "/", open_findbar);
    glide.keymaps.set("normal", "?", open_findbar);
    glide.keymaps.set("normal", "n", async () => {
      await glide.findbar.next_match();
      start_enforce_polling();
    });
    glide.keymaps.set("normal", "N", async () => {
      await glide.findbar.previous_match();
      start_enforce_polling();
    });

    glide.keymaps.set(["insert", "normal", "visual", "op-pending"], "<Esc>", async () => {
      if (glide.findbar.is_open()) {
        await glide.findbar.close();
      }
      await glide.excmds.execute("blur");
      await glide.excmds.execute("mode_change normal");
    });

    glide.keymaps.set("command", "<Esc>", () => void glide.commandline.close());

    async function tab_or_tabopen(query: string) {
      const url = query.includes("://") ? query : `https://''${query}`;
      const tabs = await browser.tabs.query({ currentWindow: true });
      const existing = tabs.find((t) => t.url != null && t.url.includes(query));
      if (existing?.id != null) {
        await browser.tabs.update(existing.id, { active: true });
        return;
      }
      const rule = match_rule(url);
      if (rule != null && container_stores[rule.container] == null) {
        await refresh_container_stores();
      }
      const target = rule != null ? container_stores[rule.container] : undefined;
      const created = await browser.tabs.create({ url, cookieStoreId: target ?? "firefox-default" });
      if (rule != null && target != null && created.id != null) {
        placed.set(created.id, rule.container);
      }
    }
  '';
}
