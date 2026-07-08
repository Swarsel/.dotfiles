{
  flake.modules.homeManager.glide = {
    programs.glide-browser.config = ''
      glide.keymaps.set("normal", "/", () => glide.findbar.open({ query: "" }));
      glide.keymaps.set("normal", "?", () => glide.findbar.open({ query: "" }));
      glide.keymaps.set("normal", "n", () => glide.findbar.next_match());
      glide.keymaps.set("normal", "N", () => glide.findbar.previous_match());

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
