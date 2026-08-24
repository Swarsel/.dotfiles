{
  flake.modules.homeManager.glide =
    { lib, vars, ... }:
    let
      engineAliases = lib.filterAttrs (_: aliases: aliases != [ ]) (
        lib.mapAttrs' (
          key: v: lib.nameValuePair (v.name or key) (v.definedAliases or [ ])
        ) vars.glide.search.engines
      );
      keywordEntries = lib.concatLists (
        lib.mapAttrsToList (
          name: aliases:
          map (alias: [
            (lib.removePrefix "@" alias)
            name
          ]) aliases
        ) engineAliases
      );
      engineList = lib.mapAttrsToList (name: aliases: {
        inherit name;
        keyword = lib.head aliases;
      }) engineAliases;
    in
    {
      programs.glide-browser.config = ''
        const engine_keywords = new Map<string, string>(
          ${builtins.toJSON keywordEntries}.flatMap(([kw, name]) => [[kw, name], ["@" + kw, name]]),
        );
        const search_engine_list: { name: string; keyword: string }[] = ${builtins.toJSON engineList};

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

        async function active_tab_info() {
          const active = await glide.tabs.active();
          const tab = await browser.tabs.get(active.id).catch(() => null);
          const incognito = tab?.incognito === true;
          return {
            id: active.id,
            incognito,
            store: incognito ? undefined : "firefox-default",
            contained: !incognito && tab != null && tab.cookieStoreId !== "firefox-default",
          };
        }

        async function do_navigate(target: "current" | "tab" | "window", url: string) {
          const { id, incognito, store, contained } = await active_tab_info();
          if (target === "window") {
            await browser.windows.create({ url, incognito });
          } else if (target === "tab" || contained) {
            await browser.tabs.create({ url, cookieStoreId: store });
          } else {
            await browser.tabs.update(id, { url });
          }
        }

        async function do_search(target: "current" | "tab" | "window", search: { query: string; engine?: string }) {
          const { id, incognito, store, contained } = await active_tab_info();
          let tab_id: number | undefined = id;
          if (target === "window") {
            tab_id = (await browser.windows.create({ incognito })).tabs?.[0]?.id;
          } else if (target === "tab" || contained) {
            tab_id = (await browser.tabs.create({ cookieStoreId: store })).id;
          }
          if (tab_id != null) {
            await browser.search.search({ ...search, tabId: tab_id });
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
      '';
    };
}
