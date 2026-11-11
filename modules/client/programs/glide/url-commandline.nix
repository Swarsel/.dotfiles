{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    type HistoryEntry = { url: string; title: string; visits: number; last_visit: number; match_title: string; match_url: string };
    type BookmarkEntry = { url: string; title: string; date_added: number; match_title: string; match_url: string };
    type UrlCandidate = { title: string; url: string; bmark: boolean; search: boolean; visits: number };

    const HISTORY_RESULTS = 50;
    const BOOKMARK_WEIGHT = 100;
    const SEARCH_URL_WEIGHT = 150;

    let history_list: HistoryEntry[] = [];
    let history_by_url = new Map<string, HistoryEntry>();
    let bookmark_list: BookmarkEntry[] = [];
    let top_sites: UrlCandidate[] = [];

    function places_fold(text: string): string {
      return text.slice(0, 255).toLowerCase().normalize("NFD").replace(/\p{M}/gu, "");
    }

    function places_unescape(url: string): string {
      try {
        return decodeURIComponent(url);
      } catch {
        return url;
      }
    }

    function places_match(tokens: string[], entry: { match_title: string; match_url: string }): boolean {
      return tokens.every((token) => entry.match_title.includes(token) || entry.match_url.includes(token));
    }

    function history_entry(item: Browser.History.HistoryItem & { url: string }): HistoryEntry {
      const title = item.title ?? "";
      return {
        url: item.url,
        title,
        visits: item.visitCount ?? 0,
        last_visit: item.lastVisitTime ?? 0,
        match_title: places_fold(title),
        match_url: places_fold(places_unescape(item.url)),
      };
    }

    async function refresh_history() {
      const items = await browser.history.search({ text: "", startTime: 0, maxResults: 2 ** 31 - 1 });
      history_list = items
        .filter((item): item is typeof item & { url: string } => item.url != null)
        .map(history_entry)
        .sort((a, b) => b.last_visit - a.last_visit);
      history_by_url = new Map(history_list.map((entry) => [entry.url, entry]));
    }

    async function refresh_bookmarks() {
      const items = await browser.bookmarks.search({});
      bookmark_list = items
        .filter((item): item is typeof item & { url: string } => URL.canParse(item.url ?? ""))
        .map((item) => ({
          url: item.url,
          title: item.title,
          date_added: item.dateAdded ?? 0,
          match_title: places_fold(item.title),
          match_url: places_fold(places_unescape(item.url)),
        }))
        .sort((a, b) => b.date_added - a.date_added);
    }

    async function refresh_top_sites() {
      top_sites = (await browser.topSites.get())
        .slice(0, HISTORY_RESULTS)
        .map((site) => ({ title: site.title ?? "", url: site.url, bmark: false, search: false, visits: 0 }));
    }

    function debounced(ms: number, fn: () => Promise<void>): () => void {
      let timer: ReturnType<typeof setTimeout> | undefined;
      return () => {
        clearTimeout(timer);
        timer = setTimeout(() => void fn(), ms);
      };
    }

    const schedule_history_refresh = debounced(1000, async () => {
      await Promise.all([refresh_history(), refresh_top_sites()]);
    });
    const schedule_bookmarks_refresh = debounced(1000, refresh_bookmarks);
    const schedule_top_sites_refresh = debounced(2000, refresh_top_sites);

    function record_visit(item: Browser.History.HistoryItem) {
      if (!item.url) {
        return;
      }
      const existing = history_by_url.get(item.url);
      if (existing != null) {
        history_list.splice(history_list.indexOf(existing), 1);
      }
      const entry = history_entry({ ...item, url: item.url, title: item.title || existing?.title });
      history_list.unshift(entry);
      history_by_url.set(entry.url, entry);
      schedule_top_sites_refresh();
    }

    function record_title(item: { url?: string; title?: string }) {
      const entry = item.url != null ? history_by_url.get(item.url) : undefined;
      if (entry != null && item.title != null) {
        entry.title = item.title;
        entry.match_title = places_fold(item.title);
      }
    }

    glide.autocmds.create("ConfigLoaded", () => {
      browser.bookmarks.onCreated.addListener(schedule_bookmarks_refresh);
      browser.bookmarks.onRemoved.addListener(schedule_bookmarks_refresh);
      browser.bookmarks.onChanged.addListener(schedule_bookmarks_refresh);
      browser.bookmarks.onMoved.addListener(schedule_bookmarks_refresh);
      browser.history.onVisited.addListener(record_visit);
      browser.history.onTitleChanged.addListener(record_title);
      browser.history.onVisitRemoved.addListener(schedule_history_refresh);
      void refresh_history();
      void refresh_bookmarks();
      void refresh_top_sites();
    });

    function search_history(tokens: string[]): HistoryEntry[] {
      const found: HistoryEntry[] = [];
      for (const entry of history_list) {
        if (found.length >= HISTORY_RESULTS) {
          break;
        }
        if (places_match(tokens, entry)) {
          found.push(entry);
        }
      }
      return found.sort((a, b) => b.visits - a.visits);
    }

    function search_bookmarks(tokens: string[]): BookmarkEntry[] {
      const seen = new Map<string, string>();
      return bookmark_list.filter((entry) => {
        if (!places_match(tokens, entry) || seen.get(entry.title) === entry.url) {
          return false;
        }
        seen.set(entry.title, entry.url);
        return true;
      });
    }

    function rewrite_search_url_query(query: string): { query: string; keyword: string | null } {
      const tokens = query.split(" ");
      const match = tokens.length > 1 || query.endsWith(" ") ? search_urls.find(([keyword]) => keyword === tokens[0]?.replace(/^@/, "")) : undefined;
      if (match == null) {
        return { query, keyword: null };
      }
      return { query: match[1].split("%s").join(" ") + " " + tokens.slice(1).join(" "), keyword: match[0] };
    }

    function combined_history_bookmarks(query: string): UrlCandidate[] {
      const tokens = places_fold(query).split(/\s+/).filter(Boolean);
      const combined = new Map<string, UrlCandidate>(
        search_bookmarks(tokens).map((b) => [b.url, { title: b.title, url: b.url, bmark: true, search: false, visits: 0 }]),
      );
      for (const page of search_history(tokens)) {
        const existing = combined.get(page.url);
        if (existing != null) {
          existing.visits = page.visits;
        } else {
          combined.set(page.url, { title: page.title, url: page.url, bmark: false, search: false, visits: page.visits });
        }
      }
      for (const [keyword, url] of search_urls) {
        if (keyword.startsWith(query.replace(/^@/, ""))) {
          combined.set(url, { title: keyword, url, bmark: false, search: true, visits: 0 });
        }
      }
      const score = (c: UrlCandidate) => -c.visits - (c.bmark ? BOOKMARK_WEIGHT : 0) - (c.search ? SEARCH_URL_WEIGHT : 0);
      return [...combined.values()].sort((a, b) => score(a) - score(b));
    }

    function decode_url_for_display(url: string): string {
      return url.replace(/(?:%[89a-f][0-9a-f])+/gi, (encoded) => {
        try {
          const decoded = decodeURIComponent(encoded);
          return /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/u.test(decoded) ? encoded : decoded;
        } catch {
          return encoded;
        }
      });
    }

    let active_fill_focused: ((focused_text: string) => string | null) | null = null;
    let active_reshow: ((url: string) => void) | null = null;
    let cmdline_input = "";

    async function url_commandline(target: "current" | "tab" | "window", opts: { prefill?: string } = {}) {
      await Promise.all([
        history_list.length === 0 ? refresh_history() : null,
        bookmark_list.length === 0 ? refresh_bookmarks() : null,
        top_sites.length === 0 ? refresh_top_sites() : null,
      ]);

      function describe_action(input: string): string {
        if (input.trim() === "") {
          return "Search with the default engine";
        }
        const resolved = resolve_open(input);
        if ("url" in resolved) {
          return "Open " + resolved.url;
        }
        return resolved.search.engine ? "Search " + resolved.search.engine + ": " + resolved.search.query : "Search: " + resolved.search.query;
      }

      cmdline_input = opts.prefill ?? "";
      active_reshow = (url) => {
        void glide.commandline.close().then(() => url_commandline(target, { ...opts, prefill: url }));
      };

      const action_text = DOM.create_element("span", { children: describe_action(opts.prefill ?? "") });
      const options: glide.CommandLineCustomOption[] = [{
        label: "search",
        render: () => DOM.create_element("td", { attributes: { colspan: "2" }, children: [action_text] }),
        matches: ({ input }) => {
          cmdline_input = input;
          action_text.textContent = describe_action(input);
          return true;
        },
        execute: ({ input }) => {
          void do_open(target, input);
        },
      }];

      const HEADER = "History and bookmarks";
      const slot_items: UrlCandidate[] = [];
      const slot_titles: HTMLElement[] = [];
      const slot_urls: HTMLElement[] = [];
      let slot_query: string | null = null;

      active_fill_focused = (focused_text) => {
        const focused = slot_items.find((_, i) => focused_text === slot_titles[i]!.textContent + slot_urls[i]!.textContent);
        if (focused == null) {
          return null;
        }
        return focused.search ? focused.title : focused.url;
      };

      function set_header(text: string) {
        const header = document.querySelector('glide-commandline [anonid="glide-commandline-completions-custom-options"] .section-header');
        if (header != null && header.textContent !== text) {
          header.textContent = text;
        }
      }

      function recompute_slots(input: string) {
        if (input === slot_query) {
          return;
        }
        slot_query = input;
        slot_items.length = 0;
        if (input === "") {
          set_header(HEADER);
          slot_items.push(...top_sites);
        } else {
          const rewritten = rewrite_search_url_query(input);
          set_header(rewritten.keyword != null ? "Search " + rewritten.keyword : HEADER);
          slot_items.push(...combined_history_bookmarks(rewritten.query).slice(0, HISTORY_RESULTS));
        }
        slot_items.forEach((item, i) => {
          slot_titles[i]!.textContent = (item.bmark ? "★ " : "") + (item.title || new URL(item.url).host);
          slot_urls[i]!.textContent = (item.search ? "Search " : "") + decode_url_for_display(item.url);
        });
      }

      for (let i = 0; i < HISTORY_RESULTS; i++) {
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
              void do_navigate(target, entry.search ? entry.url.split("%s").join("") : entry.url);
            }
          },
        });
      }

      recompute_slots(opts.prefill ?? "");
      await glide.commandline.show({ input: opts.prefill ?? "", title: HEADER, options });
    }

    glide.autocmds.create("CommandLineExit", () => {
      active_fill_focused = null;
      active_reshow = null;
    });

    glide.keymaps.set("command", "<Right>", () => {
      const focused = document.querySelector("glide-commandline .gcl-option.focused");
      const value = focused != null ? active_fill_focused?.(focused.textContent ?? "") : null;
      if (value != null && value !== cmdline_input && active_reshow != null) {
        active_reshow(value);
      } else {
        void glide.keys.send("<Right>", { skip_mappings: true });
      }
    }, { description: "Fill the focused history entry into the commandline for editing" });

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
    glide.keymaps.set("normal", "s", () => url_commandline("current", { prefill: "search " }), {
      description: "Search with the default engine",
    });
    glide.keymaps.set("normal", "S", () => url_commandline("tab", { prefill: "search " }), {
      description: "Search with the default engine in a new tab",
    });
    for (const [key, target] of [["s", "current"], ["S", "tab"]] as const) {
      glide.keymaps.set("visual", key, async () => {
        const selection = await glide.content.execute(() => window.getSelection()?.toString() ?? "", { tab_id: await glide.tabs.active() });
        await url_commandline(target, { prefill: "search " + selection });
      }, { description: "Search the selection with the default engine" + (target === "tab" ? " in a new tab" : "") });
    }
    glide.keymaps.set("normal", "w", () => url_commandline("window"), {
      description: "Open a URL or search in a new window",
    });'';
}
