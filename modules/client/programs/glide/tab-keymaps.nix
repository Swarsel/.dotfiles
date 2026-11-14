{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    glide.keymaps.set("normal", "b", "commandline_show tab ");
    glide.keymaps.set("normal", "gt", "tab_next");
    glide.keymaps.set("normal", "gT", "tab_prev");
    glide.keymaps.set("normal", "u", async () => {
      const [session] = await browser.sessions.getRecentlyClosed();
      const closed = session?.tab ?? session?.window;
      if (closed?.sessionId != null) {
        await browser.sessions.restore(closed.sessionId);
      }
    }, { description: "Restore the most recently closed tab or window" });

    glide.keymaps.set("normal", "U", async () => {
      const session = (await browser.sessions.getRecentlyClosed()).find((s) => s.window != null);
      if (session?.window?.sessionId != null) {
        await browser.sessions.restore(session.window.sessionId);
      }
    }, { description: "Restore the most recently closed window" });

    for (const [key, target] of [["p", "current"], ["P", "tab"]] as const) {
      glide.keymaps.set("normal", key, async () => {
        const text = (await navigator.clipboard.readText()).trim();
        if (text) {
          await do_open(target, text);
        }
      }, { description: "Open the clipboard contents" + (target === "tab" ? " in a new tab" : "") });
    }

    async function yank_url(url: string) {
      const decoded = decode_url_for_display(url);
      await navigator.clipboard.writeText(decoded);
      flash_message("yanked " + decoded);
    }

    glide.keymaps.set("normal", "yy", async () => {
      const tab = await glide.tabs.active();
      await yank_url(tab.url ?? "");
    }, { description: "Yank the URL of the current tab" });

    glide.keymaps.set("normal", "yf", () =>
      start_hints({
        selector: "a[href]",
        action: async ({ content }) => {
          const href = await content.execute((target) => (target as HTMLAnchorElement).href);
          if (href) {
            await yank_url(href);
          }
        },
      }), { description: "Yank a link URL using find hints" });

    async function scroll_lines(lines: number) {
      await glide.content.execute((lines: number) => {
        const line_height = (element: Element | null) => element == null ? NaN : parseInt(getComputedStyle(element).lineHeight, 10);
        const distance = lines * (line_height(document.documentElement) || line_height(document.body) || 22);
        const scrolls = (element: Element) => {
          const before = element.scrollTop;
          element.scrollTop = before + distance;
          return element.scrollTop !== before;
        };

        for (let element = document.activeElement; element != null; element = element.parentElement) {
          if (scrolls(element)) {
            return;
          }
        }

        const walker = document.createTreeWalker(document.documentElement, NodeFilter.SHOW_ELEMENT);
        do {
          if (scrolls(walker.currentNode as Element)) {
            return;
          }
        } while (walker.nextNode());
      }, { tab_id: await glide.tabs.active(), args: [lines] });
    }

    glide.keymaps.set("normal", "j", () => scroll_lines(4), { description: "Scroll down four lines" });
    glide.keymaps.set("normal", "k", () => scroll_lines(-4), { description: "Scroll up four lines" });

    glide.keymaps.set(["normal", "insert", "visual"], "<A-d>", () => {}, {
      description: "Disabled (would focus the urlbar)",
    });

    glide.keymaps.set("normal", "<C-m>", async () => {
      const tabs = await browser.tabs.query({ currentWindow: true });
      const target = tabs.sort((a, b) => (b.lastAccessed ?? 0) - (a.lastAccessed ?? 0))[1];
      if (target?.id != null) {
        await browser.tabs.update(target.id, { active: true });
      }
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
      const tabs = await browser.tabs.query({ currentWindow: true });
      const current = tabs.find((t) => t.active);
      if (current?.id == null) {
        return;
      }
      const ordered = tabs.filter((t) => t.id != null).sort((a, b) => a.index - b.index);
      const pos = ordered.findIndex((t) => t.id === current.id);
      const target = ordered[(pos - 1 + ordered.length) % ordered.length];
      if (target?.id != null && target.id !== current.id) {
        await browser.tabs.update(target.id, { active: true });
      }
      await browser.tabs.remove(current.id);
    }, { description: "Close the current tab and focus the previous one" });

    glide.keymaps.set("normal", "D", "tab_close");
  '';
}
