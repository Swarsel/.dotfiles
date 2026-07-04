{
  flake-file.inputs.glide-nix = {
    url = "github:glide-browser/glide.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  flake.modules.homeManager.glide =
    {
      config,
      pkgs,
      lib,
      vars,
      globals,
      ...
    }:
    let
      palette = lib.getAttrs [
        "base00"
        "base01"
        "base02"
        "base03"
        "base04"
        "base05"
        "base06"
        "base07"
        "base08"
        "base09"
        "base0A"
        "base0B"
        "base0C"
        "base0D"
        "base0E"
        "base0F"
      ] config.lib.stylix.colors.withHashtag;
      paletteCss = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "--${name}: ${value};") palette
      );
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "glide" ];

        programs.glide-browser = {
          enable = true;
          policies = vars.browserPolicies;
          nativeMessagingHosts = lib.optionals config.programs.password-store.enable [ pkgs.browserpass ];
          profiles.default = lib.recursiveUpdate vars.glide {
            id = 0;
            isDefault = true;
            settings."browser.startup.homepage" = "https://lobste.rs";
          };
          config = ''
            /// <reference types="./glide.d.ts" />

            glide.o.hint_size = "16px";

            glide.o.hint_label_generator = glide.hints.label_generators.numeric;
            glide.o.keymaps_use_physical_layout = "force";
            glide.o.yank_highlight = "${palette.base09}";

            glide.styles.add(css`
              :root {
                ${paletteCss}

                --glide-bg: var(--base00);
                --glide-fg: var(--base05);
                --glide-cmdl-bg: var(--base00);
                --glide-cmdl-fg: var(--base0D);
                --glide-cmdl-font-family: "Fira Code", monospace;
                --glide-cmdl-font-size: 1.5rem;
                --glide-cmdl-line-height: 1.5;
                --glide-cmplt-bg: var(--base00);
                --glide-cmplt-fg: var(--base0D);
                --glide-cmplt-font-family: "Fira Code", monospace;
                --glide-cmplt-font-size: 0.8rem;
                --glide-cmplt-border-top: unset;
                --glide-header-first-bg: var(--base01);
                --glide-header-second-bg: var(--base01);
                --glide-header-third-bg: var(--base01);
                --glide-header-font-weight: 200;
                --glide-header-border-bottom: unset;
                --glide-url-fg: var(--base0B);
                --glide-url-bg: var(--base00);
                --glide-of-bg: #44391F;
                --glide-of-fg: var(--base09);
                --glide-status-bg: var(--base00);
                --glide-status-fg: var(--base05);
                --glide-status-border: 1px solid var(--base03);
                --glide-mode-normal: var(--base03);
                --glide-mode-insert: var(--base0B);
                --glide-mode-visual: var(--base09);
                --glide-mode-hint: var(--base0E);
                --glide-mode-ignore: var(--base01);
                --glide-mode-command: var(--base0D);
                --glide-mode-op-pending: var(--base0A);
                --glide-search-highlight-color: var(--base0A);

                --lwt-accent-color: var(--base01) !important;
                --lwt-accent-color-inactive: var(--base01) !important;
                --lwt-text-color: var(--base05) !important;
                --toolbar-bgcolor: var(--base00) !important;
                --toolbar-color: var(--base05) !important;
                --toolbarbutton-icon-fill: var(--base05) !important;
                --toolbarbutton-hover-background: var(--base01) !important;
                --toolbarbutton-active-background: var(--base03) !important;
                --toolbar-field-background-color: var(--base01) !important;
                --toolbar-field-color: var(--base05) !important;
                --toolbar-field-focus-background-color: var(--base01) !important;
                --toolbar-field-focus-color: var(--base05) !important;
                --toolbar-field-border-color: transparent !important;
                --toolbar-field-focus-border-color: var(--base0D) !important;
                --urlbar-box-bgcolor: var(--base01) !important;
                --urlbar-box-focus-bgcolor: var(--base01) !important;
                --urlbar-box-hover-bgcolor: var(--base03) !important;
                --urlbar-popup-url-color: var(--base0D) !important;
                --urlbarView-highlight-background: var(--base03) !important;
                --arrowpanel-background: var(--base00) !important;
                --arrowpanel-color: var(--base05) !important;
                --arrowpanel-border-color: var(--base03) !important;
                --panel-background: var(--base00) !important;
                --panel-color: var(--base05) !important;
                --menu-background-color: var(--base00) !important;
                --menu-color: var(--base05) !important;
                --menuitem-hover-background-color: var(--base03) !important;
                --button-bgcolor: var(--base01) !important;
                --button-color: var(--base05) !important;
                --button-hover-bgcolor: var(--base03) !important;
                --button-primary-bgcolor: var(--base0C) !important;
                --button-primary-hover-bgcolor: var(--base0D) !important;
                --button-primary-color: var(--base00) !important;
                --focus-outline-color: var(--base0D) !important;
                --tab-selected-bgcolor: var(--base00) !important;
                --tab-selected-textcolor: var(--base0D) !important;
                --tab-hover-background-color: var(--base01) !important;
                --sidebar-background-color: var(--base00) !important;
                --sidebar-text-color: var(--base05) !important;
              }

              #navigator-toolbox {
                background-color: var(--base00) !important;
              }

              #TabsToolbar {
                background-color: var(--base01) !important;
              }

              #PersonalToolbar {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }

              #urlbar-background {
                background-color: var(--base01) !important;
              }

              #urlbar-container {
                max-width: 50vw !important;
              }

              findbar {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }

              .tabbrowser-tab {
                color: var(--base05) !important;
              }

              .tab-background[selected] {
                background-color: var(--base00) !important;
              }

              .tabbrowser-tab[visuallyselected] {
                color: var(--base0D) !important;
              }

              glide-commandline {
                position: fixed !important;
                top: 25% !important;
                bottom: unset !important;
                left: 10% !important;
                width: 80% !important;
                box-shadow: rgba(0, 0, 0, 0.5) 0px 0px 15px !important;
              }

              glide-commandline .glide-commandline-container {
                box-shadow: none;
              }

              glide-commandline [anonid="glide-commandline-holder"] {
                order: 1;
                border: 2px solid var(--base0C);
              }

              glide-commandline [anonid="glide-commandline-completions"] {
                order: 2;
                font-weight: 200;
              }

              glide-commandline [anonid="glide-colon"] {
                display: none;
              }

              glide-commandline input {
                padding: 1rem;
              }

              glide-commandline [anonid="glide-commandline-completions"] > div > table {
                padding: 1rem;
                padding-top: 0;
              }
            `, { id: "theme" });

            const toolbar_hidden_css = css`
              #navigator-toolbox {
                position: fixed !important;
                top: 0;
                width: 100vw;
                transform: translateY(-100%);
                opacity: 0;
                pointer-events: none;
              }

              #urlbar[popover] {
                opacity: 0 !important;
                pointer-events: none !important;
              }

              :root[customizing] #navigator-toolbox {
                position: relative !important;
                transform: none !important;
                opacity: 1 !important;
                pointer-events: auto !important;
              }

              :root[customizing] #urlbar[popover] {
                opacity: 1 !important;
                pointer-events: auto !important;
              }
            `;

            let toolbar_state: "hidden" | "urlbar" | "full" = "hidden";
            glide.styles.add(toolbar_hidden_css, { id: "toolbar-hidden" });

            function set_toolbar(state: "hidden" | "urlbar" | "full") {
              toolbar_state = state;
              glide.styles.remove("toolbar-hidden");
              if (state === "hidden") {
                glide.styles.add(toolbar_hidden_css, { id: "toolbar-hidden" });
              }
              glide.o.native_tabs = state === "urlbar" ? "hide" : "show";
            }

            glide.keymaps.set("normal", "<leader>b", () => set_toolbar(toolbar_state === "urlbar" ? "hidden" : "urlbar"), {
              description: "Toggle the URL bar",
            });
            glide.keymaps.set("normal", "<leader>B", () => set_toolbar(toolbar_state === "full" ? "hidden" : "full"), {
              description: "Toggle the full toolbar",
            });

            glide.autocmds.create("WindowLoaded", () => {
              if (!document.getElementById("glide-statusline")) {
                const profile_name = (glide.path.profile_dir.split("/").pop() ?? "").replace(/^[^.]+\./, "");
                (document.body ?? document.documentElement)?.appendChild(
                  DOM.create_element("div", {
                    id: "glide-statusline",
                    children: [
                      DOM.create_element("span", {
                        id: "glide-statusline-profile",
                        children: profile_name === "default" ? [] : [profile_name],
                      }),
                      DOM.create_element("span", { id: "glide-statusline-mode" }),
                      DOM.create_element("span", { id: "glide-statusline-tabs" }),
                      DOM.create_element("span", { id: "glide-statusline-find" }),
                      DOM.create_element("span", { id: "glide-statusline-msg" }),
                    ],
                  }),
                );
              }
              update_tab_count();
            });

            glide.styles.add(css`
              #glide-statusline {
                position: fixed;
                right: 0;
                bottom: 0;
                z-index: 2147483645;
                display: flex;
                align-items: center;
                gap: 1ex;
                padding: 0.8ex;
                background: var(--base00);
                color: var(--base05);
                border: 1px solid var(--base03);
                border-right: none;
                border-bottom: none;
                font-family: "Fira Code", monospace;
                font-size: 11px;
                line-height: 1;
                pointer-events: none;
              }

              #glide-statusline-mode {
                color: var(--glide-current-mode-color, var(--base05));
              }

              #glide-statusline-mode:empty {
                display: none;
              }

              #glide-statusline-profile {
                color: var(--base0A);
              }

              #glide-statusline-profile:empty {
                display: none;
              }

              #glide-statusline-msg {
                color: var(--base09);
              }

              #glide-statusline-msg:empty {
                display: none;
              }

              #glide-statusline-find {
                color: var(--base0B);
                font-size: 24pt;
              }

              #glide-statusline-find:empty {
                display: none;
              }

              #glide-statusline-find.nomatch {
                color: var(--base08);
              }

              #glide-hints-container > * {
                opacity: 0.6;
              }
            `, { id: "statusline" });

            let flash_timer: ReturnType<typeof setTimeout> | null = null;
            function flash_message(msg: string) {
              const msg_el = document.getElementById("glide-statusline-msg");
              if (!msg_el) {
                return;
              }
              msg_el.textContent = msg;
              if (flash_timer != null) {
                clearTimeout(flash_timer);
              }
              flash_timer = setTimeout(() => {
                msg_el.textContent = "";
              }, 2000);
            }

            glide.autocmds.create("ModeChanged", "*", ({ new_mode }) => {
              const mode_el = document.getElementById("glide-statusline-mode");
              if (mode_el) {
                mode_el.textContent = new_mode === "normal" ? "" : new_mode;
              }
            });

            async function update_tab_count() {
              for (let attempt = 0; attempt < 10; attempt++) {
                try {
                  const tabs = await browser.tabs.query({ currentWindow: true });
                  const tabs_el = document.getElementById("glide-statusline-tabs");
                  if (tabs_el) {
                    tabs_el.textContent = String(tabs.length);
                  }
                  return;
                } catch {
                  await new Promise((resolve) => setTimeout(resolve, 500));
                }
              }
            }
            browser.tabs.onCreated.addListener(update_tab_count);
            browser.tabs.onRemoved.addListener(update_tab_count);

            const search_engines = [
              {
                name: "NixOS Options",
                keyword: "no",
                search_url: "https://search.nixos.org/options?query={searchTerms}",
              },
              {
                name: "Nix Packages",
                keyword: "np",
                search_url: "https://search.nixos.org/packages?query={searchTerms}",
              },
              {
                name: "Home Manager Options",
                keyword: "hm",
                search_url: "https://home-manager-options.extranix.com/?query={searchTerms}",
              },
              {
                name: "YouTube",
                keyword: "yt",
                search_url: "https://www.youtube.com/results?search_query={searchTerms}",
              },
              {
                name: "GitHub",
                keyword: "gh",
                search_url: "https://github.com/search?q={searchTerms}",
              },
              {
                name: "Confluence search",
                keyword: "@c",
                search_url: "https://vbc.atlassian.net/wiki/search?text={searchTerms}",
              },
              {
                name: "Jira search",
                keyword: "@j",
                search_url: "https://vbc.atlassian.net/issues/?jql=textfields%20~%20%22{searchTerms}*%22&wildcardFlag=true",
              },
            ];
            const engine_keywords = new Map(search_engines.map((e) => [e.keyword, e.name]));

            function parse_search(args_arr: string[]): { query: string; engine?: string } {
              const [first, ...rest] = args_arr;
              if (first != null && rest.length > 0 && engine_keywords.has(first)) {
                return { query: rest.join(" "), engine: engine_keywords.get(first) };
              }
              return { query: args_arr.join(" ") };
            }

            function to_url(input: string): string | null {
              if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(input)) return input;
              if (!input.includes(" ") && input.includes(".")) return `https://''${input}`;
              return null;
            }

            async function do_navigate(target: "current" | "tab" | "window", url: string) {
              if (target === "current") {
                const tab = await glide.tabs.active();
                await browser.tabs.update(tab.id, { url });
              } else if (target === "tab") {
                await browser.tabs.create({ url });
              } else {
                await browser.windows.create({ url });
              }
            }

            async function do_search(target: "current" | "tab" | "window", search: { query: string; engine?: string }) {
              if (target === "current") {
                const tab = await glide.tabs.active();
                await browser.search.search({ ...search, tabId: tab.id });
              } else if (target === "tab") {
                await browser.search.search(search);
              } else {
                const win = await browser.windows.create();
                const tab = win.tabs?.[0];
                if (tab?.id != null) {
                  await browser.search.search({ ...search, tabId: tab.id });
                }
              }
            }

            async function do_open(target: "current" | "tab" | "window", input: string) {
              const url = to_url(input.trim());
              if (url) {
                await do_navigate(target, url);
              } else {
                await do_search(target, parse_search(input.split(" ").filter(Boolean)));
              }
            }

            glide.excmds.create({ name: "open", description: "Open a URL or search in the current tab" }, ({ args_arr }) => do_open("current", args_arr.join(" ")));
            glide.excmds.create({ name: "tabopen", description: "Open a URL or search in a new tab" }, ({ args_arr }) => do_open("tab", args_arr.join(" ")));
            glide.excmds.create({ name: "winopen", description: "Open a URL or search in a new window" }, ({ args_arr }) => do_open("window", args_arr.join(" ")));
            glide.excmds.create({ name: "search", description: "Search in the current tab" }, ({ args_arr }) => do_search("current", parse_search(args_arr)));
            glide.excmds.create({ name: "tabsearch", description: "Search in a new tab" }, ({ args_arr }) => do_search("tab", parse_search(args_arr)));

            let url_entries: { star: boolean; title: string; url: string }[] = [];
            let url_entries_timer: ReturnType<typeof setTimeout> | null = null;

            async function refresh_url_entries() {
              const [bookmarks, history] = await Promise.all([
                browser.bookmarks.search({}),
                browser.history.search({ text: "", startTime: 0, maxResults: 300 }),
              ]);
              const seen = new Set();
              const entries: typeof url_entries = [];
              for (const item of [...bookmarks.map((b) => ({ ...b, star: true })), ...history.map((h) => ({ ...h, star: false }))]) {
                if (!item.url || seen.has(item.url)) continue;
                seen.add(item.url);
                entries.push({ star: item.star, title: item.title ?? "", url: item.url });
              }
              url_entries = entries;
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
              void refresh_url_entries();
            });
            browser.bookmarks.onCreated.addListener(schedule_url_entries_refresh);
            browser.bookmarks.onRemoved.addListener(schedule_url_entries_refresh);
            browser.bookmarks.onChanged.addListener(schedule_url_entries_refresh);
            browser.bookmarks.onMoved.addListener(schedule_url_entries_refresh);
            browser.history.onVisited.addListener(schedule_url_entries_refresh);

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

              const SLOTS = 30;
              const slot_items: (typeof url_entries)[number][] = [];
              const slot_titles: HTMLElement[] = [];
              const slot_urls: HTMLElement[] = [];
              let slot_query: string | null = null;

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
                for (let i = 0; i < slot_items.length; i++) {
                  slot_titles[i].textContent = (slot_items[i].star ? "★ " : "") + (slot_items[i].title || slot_items[i].url);
                  slot_urls[i].textContent = slot_items[i].url;
                }
              }

              for (let i = 0; i < SLOTS; i++) {
                const title_el = DOM.create_element("span", { style: { overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" } });
                const url_el = DOM.create_element("span", { style: { color: "var(--base0B)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" } });
                slot_titles.push(title_el);
                slot_urls.push(url_el);
                options.push({
                  label: "url-" + i,
                  render: () => DOM.create_element("td", {
                    attributes: { colspan: "2" },
                    style: { display: "flex", justifyContent: "space-between", gap: "2em", overflow: "hidden" },
                    children: [title_el, url_el],
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
            });
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

            let last_tab_id: number | null = null;
            browser.tabs.onActivated.addListener((info) => {
              if (info.previousTabId != null) {
                last_tab_id = info.previousTabId;
              }
            });
            glide.keymaps.set("normal", "<C-m>", async () => {
              if (last_tab_id != null) {
                await browser.tabs.update(last_tab_id, { active: true }).catch(() => {});
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
              const current = await glide.tabs.active();
              await glide.excmds.execute("tab_prev");
              if (current.id != null) {
                await browser.tabs.remove(current.id);
              }
            }, { description: "Close the current tab and focus the previous one" });

            glide.keymaps.set("normal", "D", "tab_close");

            let hint_session = false;
            let hint_filter = "";
            let hint_texts: string[] = [];
            let hint_active = 0;
            let hint_visible: number[] = [];

            let hint_cooldown_until = 0;
            let swallowing_keys = false;

            async function swallow_keys(ms: number) {
              hint_cooldown_until = Date.now() + ms;
              if (swallowing_keys) {
                return;
              }
              swallowing_keys = true;
              try {
                while (true) {
                  const key = await glide.keys.next();
                  if (Date.now() >= hint_cooldown_until) {
                    await glide.keys.send(key);
                    return;
                  }
                }
              } finally {
                swallowing_keys = false;
              }
            }

            function hint_label_is_ambiguous(label: string, count: number): boolean {
              for (let m = 1; m <= count; m++) {
                const s = String(m);
                if (s !== label && s.startsWith(label)) {
                  return true;
                }
              }
              return false;
            }

            function update_find_display(no_match = false) {
              const find_el = document.getElementById("glide-statusline-find");
              if (!find_el) {
                return;
              }
              find_el.textContent = hint_session ? "find: " + hint_filter : "";
              find_el.classList.toggle("nomatch", hint_session && no_match);
            }

            function follow_hint(index: number) {
              hint_session = false;
              const label = String(index + 1);
              void glide.keys
                .send(hint_label_is_ambiguous(label, hint_texts.length) ? label + "<Enter>" : label)
                .then(() => swallow_keys(500));
            }

            function apply_hint_filter(reset_active = true) {
              const container = document.getElementById("glide-hints-container");
              if (!container) {
                return;
              }
              hint_visible = [];
              for (let i = 0; i < container.children.length; i++) {
                if ((hint_texts[i] ?? "").includes(hint_filter)) {
                  hint_visible.push(i);
                }
              }
              if (reset_active || hint_visible.length === 0) {
                hint_active = 0;
              } else {
                hint_active = ((hint_active % hint_visible.length) + hint_visible.length) % hint_visible.length;
              }
              for (let i = 0; i < container.children.length; i++) {
                const marker = container.children[i] as HTMLElement;
                const pos = hint_visible.indexOf(i);
                marker.style.display = pos === -1 ? "none" : "";
                const active = pos === hint_active && pos !== -1;
                marker.style.background = active ? "var(--base0B)" : "";
                marker.style.color = active ? "var(--base00)" : "";
                marker.style.opacity = active ? "1" : "";
              }
              update_find_display(hint_filter.length > 0 && hint_visible.length === 0);
              if (hint_session && hint_filter.length > 0 && hint_visible.length === 1) {
                follow_hint(hint_visible[0]);
              }
            }

            function start_hints(selector?: string, action?: glide.HintAction) {
              hint_session = true;
              hint_filter = "";
              hint_texts = [];
              hint_active = 0;
              hint_visible = [];
              update_find_display();
              glide.hints.show({
                selector,
                action,
                async pick({ hints, content }) {
                  hint_texts = await content.map((target) => (target.textContent ?? "").toLowerCase());
                  setTimeout(() => apply_hint_filter(), 0);
                  return hints;
                },
              });
            }

            glide.keymaps.set("normal", "c", () => start_hints());
            glide.keymaps.set("normal", "f", () => start_hints());
            glide.keymaps.set("normal", "F", () => start_hints(undefined, "newtab-click"));

            for (const ch of "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-:./_,;!?@#%^&*()+=[]{}~'\"$") {
              glide.keymaps.set("hint", ch, () => {
                if (hint_session) {
                  hint_filter += ch.toLowerCase();
                  apply_hint_filter();
                }
              });
            }
            glide.keymaps.set("hint", "<Space>", () => {
              if (hint_session) {
                hint_filter += " ";
                apply_hint_filter();
              }
            });
            glide.keymaps.set("hint", "\\", async () => {
              if (!hint_session) {
                return;
              }
              const key = (await glide.keys.next()) as any;
              const ch = typeof key === "string" ? key : String(key?.key ?? "");
              if (ch.length === 1) {
                hint_filter += ch.toLowerCase();
                apply_hint_filter();
              }
            });
            glide.keymaps.set("hint", "<Enter>", () => {
              if (hint_session && hint_visible.length > 0) {
                follow_hint(hint_visible[hint_active]);
              }
            });
            glide.keymaps.set("hint", "<Tab>", () => {
              if (hint_session) {
                hint_active += 1;
                apply_hint_filter(false);
              }
            });
            glide.keymaps.set("hint", "<S-Tab>", () => {
              if (hint_session) {
                hint_active -= 1;
                apply_hint_filter(false);
              }
            });
            glide.keymaps.set("hint", "<BS>", () => {
              if (hint_session) {
                hint_filter = hint_filter.slice(0, -1);
                apply_hint_filter();
              }
            });
            glide.autocmds.create("ModeChanged", "*", ({ new_mode }) => {
              if (new_mode !== "hint") {
                hint_session = false;
                update_find_display();
              }
            });

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
                await glide.excmds.execute(`tab_new ''${url}`);
              }
            }

            const site_shortcuts = {
              gwa: "apic-impimba-1.m.imp.ac.at",
              gwA: "artifactory.imp.ac.at",
              gwb: "bitbucket.vbc.ac.at",
              gwc: "vbc.atlassian.net/wiki",
              gwd: "datadomain-impimba-2.imp.ac.at",
              gwe: "exivity.vbc.ac.at",
              gwg: "github.com",
              gwG: "goc.egi.eu",
              gwh: "jupyterhub.vbc.ac.at",
              gwj: "jenkins.vbc.ac.at",
              gwJ: "test-jenkins.vbc.ac.at",
              gwl: "lucid.app",
              gwm: "monitoring.vbc.ac.at/grafana",
              gwM: "monitoring.vbc.ac.at/prometheus",
              gwn: "netbox.vbc.ac.at",
              gwN: "nap.imp.ac.at",
              gwo: "outlook.office.com",
              gws: "satellite.vbc.ac.at",
              gwt: "tower.vbc.ac.at",
              gwv: "vc-impimba-1.m.imp.ac.at/ui",
              gwx: "xclarity.vbc.ac.at",
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
            };

            for (const [keys, target] of Object.entries(site_shortcuts)) {
              glide.keymaps.set("normal", keys, () => tab_or_tabopen(target), {
                description: `Focus or open ''${target}`,
              });
            }

            const hint_selectors = {
              "https?://www\\.google\\.com": `[class="LC20lb MBeuO DKV0Md"], [class="YmvwI"], [class="YyVfkd"], [class="fl"]`,
              "https?://news\\.ycombinator\\.com": `[class="titleline"], [class="age"]`,
              "https?://lobste\\.rs": `[class="u-url"], [class="comments_label"]`,
              "https?://(www\\.|old\\.)?reddit\\.com": `[class="title may-blank loggedin"], [class="bylink comments may-blank"]`,
              "https?://github\\.com": `[class="Link--primary"], [class="AppHeader-button Button--secondary Button--medium Button p-0 color-fg-muted"], [class="UnderlineNav-item no-wrap js-responsive-underlinenav-item js-selected-navigation-item"], [class="prc-ActionList-ItemLabel-TmBhn"], [class="PRIVATE_TreeView-item-content-text prc-TreeView-TreeViewItemContentText-smZM-"]`,
              "https?://vbc\\.atlassian\\.net/wiki": `[class="_1reo15vq _18m915vq _1bto1l2s _kqswh2mm _o5721q9c _syaz1fxt"], [class="_11c81ixg _1reo15vq _18m915vq _18s81b66 _kqswh2mm _k48p1wq8 _o5721q9c _1bto1l2s _u5f31b66"], [class="_1r04ze3t _kqswstnw"], [class="css-a61etj"], [class="jira-macro-table-underline-pdfexport"]`,
            };

            for (const [pattern, selector] of Object.entries(hint_selectors)) {
              glide.autocmds.create("UrlEnter", new RegExp(pattern), () => {
                glide.buf.keymaps.set("normal", "c", () => start_hints(selector));
              });
            }

            glide.autocmds.create("UrlEnter", /https?:\/\/www\.google\.com/, () => {
              glide.buf.keymaps.set("normal", "gi", async () => {
                await glide.excmds.execute("focusinput last");
                await glide.excmds.execute("caret_move endline");
              });
            });

            const invidious_css = css`
              body {
                max-width: 100% !important;
                margin: 0 !important;
                padding: 0 !important;
              }

              .pure-u-md-2-3,
              .pure-u-lg-2-3,
              .pure-u-md-1-3,
              .pure-u-lg-1-3 {
                width: 100% !important;
              }

              #contents,
              .pure-g,
              .pure-u-md-2-3 > .h-box,
              .pure-u-lg-2-3 > .h-box {
                max-width: 100% !important;
                width: 100% !important;
                padding-left: 0 !important;
                padding-right: 0 !important;
                margin-left: 0 !important;
                margin-right: 0 !important;
              }

              #player-container {
                width: 100% !important;
                max-width: 100% !important;
                aspect-ratio: 16 / 9;
                height: auto !important;
                padding: 0 !important;
                margin: 0 !important;
                max-height: 90vh !important;
              }

              .video-js,
              .video-js video,
              .video-js .vjs-tech,
              #player {
                width: 100% !important;
                height: 100% !important;
                padding-top: 0 !important;
              }

              #player-container + .h-box,
              #player-container + div {
                margin-top: 0.5em !important;
                padding-top: 0 !important;
              }
            `;

            glide.autocmds.create("UrlEnter", /https:\/\/${
              lib.replaceStrings [ "." ] [ "\\." ] globals.services.invidious.domain
            }\/watch/, ({ tab_id }) => {
              glide.content.execute((css_text) => {
                if (!document.getElementById("glide-user-style")) {
                  const el = document.createElement("style");
                  el.id = "glide-user-style";
                  el.textContent = css_text;
                  document.head.appendChild(el);
                }
              }, { tab_id, args: [invidious_css] });
            });

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

            for (const pattern of ignore_mode_sites) {
              glide.autocmds.create("UrlEnter", pattern, () => {
                glide.excmds.execute("mode_change ignore");
              });
            }
          '';
        };

        programs.zsh.sessionVariables = {
          MOZ_DISABLE_RDD_SANDBOX = "1";
        };

        home.activation.sponsorblockSettings = vars.sponsorblockActivation;
      };
    };
}
