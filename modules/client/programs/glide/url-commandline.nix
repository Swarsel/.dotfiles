{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    let url_entries: { star: boolean; title: string; url: string }[] = [];
    let url_entry_set = new Set<string>();
    const live_history = new Map<string, { star: boolean; title: string; url: string }>();
    let url_entries_timer: ReturnType<typeof setTimeout> | null = null;

    async function refresh_url_entries() {
      const [bookmarks, history] = await Promise.all([
        browser.bookmarks.search({}),
        browser.history.search({ text: "", startTime: 0, maxResults: 1000 }),
      ]);
      history.sort((a, b) => (b.lastVisitTime ?? 0) - (a.lastVisitTime ?? 0));
      const seen = new Set<string>();
      const entries: typeof url_entries = [];
      for (const item of [...history.map((h) => ({ ...h, star: false })), ...bookmarks.map((b) => ({ ...b, star: true }))]) {
        if (!item.url || seen.has(item.url)) continue;
        seen.add(item.url);
        entries.push({ star: item.star, title: item.title ?? "", url: item.url });
      }
      url_entries = entries;
      url_entry_set = seen;
    }

    function schedule_url_entries_refresh() {
      try {
        if (url_entries_timer != null) {
          clearTimeout(url_entries_timer);
        }
        url_entries_timer = setTimeout(() => {
          url_entries_timer = null;
          void refresh_url_entries();
        }, 1000);
      } catch {
        return;
      }
    }

    glide.autocmds.create("ConfigLoaded", () => {
      browser.bookmarks.onCreated.addListener(schedule_url_entries_refresh);
      browser.bookmarks.onRemoved.addListener(schedule_url_entries_refresh);
      browser.bookmarks.onChanged.addListener(schedule_url_entries_refresh);
      browser.bookmarks.onMoved.addListener(schedule_url_entries_refresh);
      browser.history.onVisited.addListener(schedule_url_entries_refresh);
      void refresh_url_entries();
    });

    async function url_commandline(target: "current" | "tab" | "window", opts: { prefill?: string; search_only?: boolean } = {}) {
      if (url_entries.length === 0) {
        await refresh_url_entries();
      }

      function describe_action(input: string): string {
        const trimmed = input.trim();
        if (trimmed === "") {
          return "Search with the default engine";
        }
        if (!opts.search_only) {
          const url = to_url(trimmed);
          if (url) {
            return "Open " + url;
          }
        }
        const search = parse_search(trimmed.split(" ").filter(Boolean));
        return search.engine ? "Search " + search.engine + ": " + search.query : "Search: " + search.query;
      }

      const action_text = DOM.create_element("span", { children: describe_action(opts.prefill ?? "") });
      const options: glide.CommandLineCustomOption[] = [{
        label: "search",
        render: () => DOM.create_element("td", { attributes: { colspan: "2" }, children: [action_text] }),
        matches: ({ input }) => {
          action_text.textContent = describe_action(input);
          return true;
        },
        execute: ({ input }) => {
          if (opts.search_only) {
            do_search(target, parse_search(input.split(" ").filter(Boolean)));
          } else {
            do_open(target, input);
          }
        },
      }];

      function query_without_keyword(input: string): string {
        const parts = input.trim().split(" ").filter(Boolean);
        if (parts.length >= 1 && engine_keywords.has(parts[0])) {
          return parts.slice(1).join(" ");
        }
        return input.trim();
      }

      for (const engine of search_engine_list) {
        const kw_el = DOM.create_element("span", { style: { color: "var(--base0A)", whiteSpace: "nowrap" }, children: [engine.keyword] });
        const name_el = DOM.create_element("span", { style: { color: "var(--base05)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }, children: ["Search using " + engine.name] });
        options.push({
          label: "engine-" + engine.keyword,
          render: () => DOM.create_element("td", {
            attributes: { colspan: "2" },
            children: [
              DOM.create_element("div", {
                style: { display: "flex", width: "100%", minWidth: "0", gap: "1.5em", overflow: "hidden" },
                children: [kw_el, name_el],
              }),
            ],
          }),
          matches: ({ input }) => {
            const first = input.trim().split(" ").filter(Boolean)[0];
            const keyword_match = first != null && engine_keywords.get(first) === engine.name;
            if (!opts.search_only && !keyword_match) {
              return false;
            }
            const q = query_without_keyword(input);
            name_el.textContent = q === "" ? "Search using " + engine.name : "Search using " + engine.name + ": " + q;
            return true;
          },
          execute: ({ input }) => {
            void do_search(target, { query: query_without_keyword(input), engine: engine.name });
          },
        });
      }

      const SLOTS = 30;
      const slot_items: (typeof url_entries)[number][] = [];
      const slot_titles: HTMLElement[] = [];
      const slot_urls: HTMLElement[] = [];
      let slot_query: string | null = null;
      let live_query: string | null = null;

      async function fetch_live(q: string) {
        if (live_query === q) {
          return;
        }
        live_query = q;
        const results = await browser.history.search({ text: q, startTime: 0, maxResults: 100 });
        let added = false;
        for (const item of results) {
          if (!item.url || url_entry_set.has(item.url) || live_history.has(item.url)) continue;
          live_history.set(item.url, { star: false, title: item.title ?? "", url: item.url });
          added = true;
        }
        if (added && slot_query != null && slot_query.trim().toLowerCase() === q) {
          const current = slot_query;
          slot_query = null;
          recompute_slots(current);
        }
      }

      function recompute_slots(input: string) {
        if (input === slot_query) {
          return;
        }
        slot_query = input;
        const q = input.trim().toLowerCase();
        slot_items.length = 0;
        for (const entry of url_entries) {
          if (slot_items.length >= SLOTS) break;
          if (q === "" || entry.title.toLowerCase().includes(q) || entry.url.toLowerCase().includes(q)) {
            slot_items.push(entry);
          }
        }
        if (q !== "") {
          for (const entry of live_history.values()) {
            if (slot_items.length >= SLOTS) break;
            if (!url_entry_set.has(entry.url) && (entry.title.toLowerCase().includes(q) || entry.url.toLowerCase().includes(q))) {
              slot_items.push(entry);
            }
          }
          void fetch_live(q);
        }
        for (let i = 0; i < slot_items.length; i++) {
          slot_titles[i].textContent = (slot_items[i].star ? "★ " : "") + (slot_items[i].title || slot_items[i].url);
          slot_urls[i].textContent = slot_items[i].url;
        }
      }

      for (let i = 0; i < SLOTS; i++) {
        const title_el = DOM.create_element("span", { style: { flex: "1 1 50%", minWidth: "0", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" } });
        const url_el = DOM.create_element("span", { style: { flex: "1 1 50%", minWidth: "0", textAlign: "right", color: "var(--base0B)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" } });
        slot_titles.push(title_el);
        slot_urls.push(url_el);
        options.push({
          label: "url-" + i,
          render: () => DOM.create_element("td", {
            attributes: { colspan: "2" },
            children: [
              DOM.create_element("div", {
                style: { display: "flex", width: "100%", minWidth: "0", justifyContent: "space-between", gap: "2em", overflow: "hidden" },
                children: [title_el, url_el],
              }),
            ],
          }),
          matches: ({ input }) => {
            recompute_slots(input);
            return slot_items[i] != null;
          },
          execute: () => {
            const entry = slot_items[i];
            if (entry) {
              void do_navigate(target, entry.url);
            }
          },
        });
      }

      recompute_slots(opts.prefill ?? "");
      await glide.commandline.show({ input: opts.prefill ?? "", title: "History and bookmarks", options });
    }

    glide.keymaps.set("normal", "o", () => url_commandline("current"), {
      description: "Open a URL or search",
    });
    glide.keymaps.set("normal", "O", async () => {
      const tab = await glide.tabs.active();
      await url_commandline("current", { prefill: tab.url });
    }, { description: "Edit the current URL" });
    glide.keymaps.set("normal", "t", () => url_commandline("tab"), {
      description: "Open a URL or search in a new tab",
    });
    glide.keymaps.set("normal", "T", async () => {
      const tab = await glide.tabs.active();
      await url_commandline("tab", { prefill: tab.url });
    }, { description: "Open the current URL in a new tab" });
    glide.keymaps.set("normal", "s", () => url_commandline("current", { search_only: true }), {
      description: "Search with the default engine",
    });
    glide.keymaps.set("normal", "S", () => url_commandline("tab", { search_only: true }), {
      description: "Search with the default engine in a new tab",
    });
    glide.keymaps.set("normal", "w", () => url_commandline("window"), {
      description: "Open a URL or search in a new window",
    });'';
}
