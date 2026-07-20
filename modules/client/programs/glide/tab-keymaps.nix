{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    glide.keymaps.set("normal", "b", "commandline_show tab ");
    glide.keymaps.set("normal", "gt", "tab_next");
    glide.keymaps.set("normal", "gT", "tab_prev");
    glide.keymaps.set("normal", "u", "tab_reopen");

    glide.keymaps.set("normal", "p", async () => {
      const text = (await navigator.clipboard.readText()).trim();
      if (text) {
        await do_open("current", text);
      }
    }, { description: "Open the clipboard contents" });

    glide.keymaps.set("normal", "yy", async () => {
      const tab = await glide.tabs.active();
      const url = tab.url ?? "";
      await navigator.clipboard.writeText(url);
      flash_message("yanked " + url);
    }, { description: "Yank the URL of the current tab" });

    glide.keymaps.set("normal", "yf", () =>
      start_hints("a[href]", async ({ content }) => {
        const href = await content.execute((target) => (target as HTMLAnchorElement).href);
        if (href) {
          await navigator.clipboard.writeText(href);
          flash_message("yanked " + href);
        }
      }), { description: "Yank a link URL using find hints" });

    glide.keymaps.set(["normal", "insert", "visual"], "<A-d>", () => {}, {
      description: "Disabled (would focus the urlbar)",
    });

    glide.keymaps.set("normal", "<C-m>", async () => {
      try {
        const win = await browser.windows.getLastFocused({ populate: true });
        const tabs = (win.tabs ?? [])
          .filter((t) => t.id != null)
          .sort((a, b) => (b.lastAccessed ?? 0) - (a.lastAccessed ?? 0));
        const target = tabs[1];
        if (target?.id != null) {
          await browser.tabs.update(target.id, { active: true });
        }
      } catch {}
    }, { description: "Switch to the last-active tab" });

    glide.keymaps.set("normal", "gd", async () => {
      const tab = await glide.tabs.active();
      await browser.windows.create({ tabId: tab.id });
    }, { description: "Detach the current tab into a new window" });

    glide.keymaps.set("normal", "gD", async () => {
      const tab = await glide.tabs.active();
      const dup = await browser.tabs.duplicate(tab.id);
      if (dup?.id != null) {
        await browser.windows.create({ tabId: dup.id });
      }
    }, { description: "Duplicate the current tab into a new window" });

    glide.keymaps.set("normal", "d", async () => {
      const current = await glide.tabs.active();
      await glide.excmds.execute("tab_prev");
      if (current.id != null) {
        await browser.tabs.remove(current.id);
      }
    }, { description: "Close the current tab and focus the previous one" });

    glide.keymaps.set("normal", "D", "tab_close");
  '';
}
