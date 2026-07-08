{
  flake.modules.homeManager.glide = {
    programs.glide-browser.config = ''
      function ensure_statusline() {
        const stale = document.getElementById("glide-statusline");
        if (stale && !document.getElementById("glide-statusline-container")) {
          stale.remove();
        }
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
                DOM.create_element("span", { id: "glide-statusline-container" }),
                DOM.create_element("span", { id: "glide-statusline-mode" }),
                DOM.create_element("span", { id: "glide-statusline-tabs" }),
                DOM.create_element("span", { id: "glide-statusline-find" }),
                DOM.create_element("span", { id: "glide-statusline-msg" }),
              ],
            }),
          );
        }
        update_tab_count();
        void refresh_active_container();
      }

      glide.autocmds.create("WindowLoaded", ensure_statusline);
      glide.autocmds.create("ConfigLoaded", () => {
        if (document.getElementById("glide-statusline")) {
          ensure_statusline();
        }
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

        #glide-statusline-container {
          color: var(--base0C);
        }

        #glide-statusline-container:empty {
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
      function update_container_indicator(store_id?: string) {
        const container_el = document.getElementById("glide-statusline-container");
        if (!container_el) {
          return;
        }
        container_el.textContent =
          store_id != null && store_id !== "firefox-default" ? (container_names[store_id] ?? "") : "";
      }
      async function refresh_active_container() {
        try {
          const win = await browser.windows.getLastFocused({ populate: true });
          const active = win.tabs?.find((t) => t.active);
          await update_container_indicator(active?.cookieStoreId);
        } catch {}
      }
      const tab_containers: Record<number, string> = {};
      function cache_tab(tab: { id?: number; cookieStoreId?: string } | null | undefined) {
        if (tab?.id != null && tab.cookieStoreId != null) {
          tab_containers[tab.id] = tab.cookieStoreId;
        }
      }
      glide.autocmds.create("ConfigLoaded", () => {
        browser.tabs.onCreated.addListener(update_tab_count);
        browser.tabs.onRemoved.addListener(update_tab_count);
        browser.tabs.onCreated.addListener(cache_tab);
        browser.tabs.onRemoved.addListener((tab_id) => {
          delete tab_containers[tab_id];
        });
        browser.tabs.onActivated.addListener(async (info) => {
          const cached = tab_containers[info.tabId];
          if (cached != null) {
            update_container_indicator(cached);
            return;
          }
          const tab = await browser.tabs.get(info.tabId).catch(() => null);
          cache_tab(tab);
          update_container_indicator(tab?.cookieStoreId);
        });
        browser.tabs.onUpdated.addListener((_tab_id, _change, tab) => {
          cache_tab(tab);
          if (tab.active) {
            update_container_indicator(tab.cookieStoreId);
          }
        });
        browser.windows.onFocusChanged.addListener(() => void refresh_active_container());
      });
      setInterval(() => void refresh_active_container(), 1500);
    '';
  };
}
