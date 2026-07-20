{
  flake.modules.homeManager.glide = {
    programs.glide-browser.config = ''
      const container_rules: { prefix: string; container: string }[] = [];
      const container_stores: Record<string, string> = {};
      const container_names: Record<string, string> = {};

      function match_rule(url: string) {
        let best: { prefix: string; container: string } | null = null;
        for (const r of container_rules) {
          if (url.startsWith(r.prefix) && (best == null || r.prefix.length > best.prefix.length)) {
            best = r;
          }
        }
        return best;
      }

      async function refresh_container_stores() {
        try {
          for (const identity of await browser.contextualIdentities.query({})) {
            container_stores[identity.name] = identity.cookieStoreId;
            container_names[identity.cookieStoreId] = identity.name;
          }
        } catch {}
      }

      const reopening = new Set<number>();
      const placed = new Map<number, string>();
      async function ensure_container(tab_id: number, url: string) {
        const rule = match_rule(url);
        if (!rule || reopening.has(tab_id) || placed.get(tab_id) === rule.container) {
          return;
        }
        reopening.add(tab_id);
        try {
          if (container_stores[rule.container] == null) {
            await refresh_container_stores();
          }
          const target = container_stores[rule.container];
          if (target == null) {
            return;
          }
          const tab = await browser.tabs.get(tab_id).catch(() => null);
          if (tab == null || tab.cookieStoreId === target) {
            if (tab != null) {
              placed.set(tab_id, rule.container);
            }
            return;
          }
          const created = await browser.tabs.create({
            cookieStoreId: target,
            url,
            active: tab.active,
            windowId: tab.windowId,
            index: tab.index + 1,
          });
          if (created.id != null) {
            placed.set(created.id, rule.container);
          }
          await browser.tabs.remove(tab_id);
        } catch {} finally {
          reopening.delete(tab_id);
        }
      }

      browser.tabs.onRemoved.addListener((tab_id) => placed.delete(tab_id));

      async function container_catchup() {
        try {
          for (const tab of await browser.tabs.query({})) {
            if (tab.id != null && tab.url != null) {
              await ensure_container(tab.id, tab.url);
            }
          }
        } catch {}
      }

      glide.autocmds.create("ConfigLoaded", async () => {
        try {
          browser.webRequest.onBeforeRequest.addListener(
            (details) => {
              if (details.tabId >= 0 && match_rule(details.url)) {
                void ensure_container(details.tabId, details.url);
              }
            },
            { urls: ["<all_urls>"], types: ["main_frame"] },
          );
        } catch {}
        browser.contextualIdentities.onCreated.addListener(() => void refresh_container_stores());
        await refresh_container_stores();
        await container_catchup();
      });

      glide.autocmds.create("UrlEnter", /^https?:/, ({ url, tab_id }) => {
        void ensure_container(tab_id, url);
      });

      glide.keymaps.set("normal", "<leader>c", async () => {
        try {
          const identities = await browser.contextualIdentities.query({});
          if (identities.length === 0) {
            flash_message("no containers defined");
            return;
          }
          const [current] = await browser.tabs.query({ active: true, currentWindow: true });
          const url = current?.url != null && current.url.startsWith("http") ? current.url : undefined;
          await glide.commandline.show({
            title: "Open in container",
            options: identities.map((identity) => ({
              label: identity.name,
              description: (url ? "open current page as " : "open new tab as ") + identity.name,
              execute: async () => {
                await browser.tabs.create({ cookieStoreId: identity.cookieStoreId, url });
              },
            })),
          });
        } catch {
          flash_message("containers unavailable");
        }
      }, { description: "Open the current page in a container tab" });

      glide.keymaps.set("normal", "<leader>B", () => set_toolbar(toolbar_state === "full" ? "hidden" : "full"), {
        description: "Toggle the full toolbar",
      });
    '';
  };
}
