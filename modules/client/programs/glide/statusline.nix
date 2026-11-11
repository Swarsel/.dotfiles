{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    function ensure_statusline() {
      if (!document.getElementById("glide-statusline")) {
        const profile_name = (glide.path.profile_dir.split("/").pop() ?? "").replace(/^[^.]+\./, "");
        (document.body ?? document.documentElement).appendChild(
          DOM.create_element("div", {
            id: "glide-statusline",
            children: [
              DOM.create_element("span", {
                id: "glide-statusline-profile",
                children: profile_name === "default" ? [] : [profile_name],
              }),
              DOM.create_element("span", { id: "glide-statusline-container" }),
              DOM.create_element("span", { id: "glide-statusline-root" }),
              DOM.create_element("span", { id: "glide-statusline-mode" }),
              DOM.create_element("span", { id: "glide-statusline-tabs" }),
              DOM.create_element("span", { id: "glide-statusline-find" }),
              DOM.create_element("span", { id: "glide-statusline-msg" }),
            ],
          }),
        );
      }
      void update_tab_count();
      void refresh_active_indicators();
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

      #glide-statusline-root {
        color: var(--base0D);
      }

      #glide-statusline-root:empty {
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

    let flash_timer: ReturnType<typeof setTimeout> | undefined;
    function flash_message(msg: string) {
      const msg_el = document.getElementById("glide-statusline-msg");
      if (!msg_el) {
        return;
      }
      msg_el.textContent = msg;
      clearTimeout(flash_timer);
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
      const tabs = await browser.tabs.query({ currentWindow: true });
      const tabs_el = document.getElementById("glide-statusline-tabs");
      if (tabs_el) {
        tabs_el.textContent = String(tabs.length);
      }
    }

    function update_container_indicator(store_id?: string) {
      const container_el = document.getElementById("glide-statusline-container");
      if (!container_el) {
        return;
      }
      container_el.textContent = store_id != null && store_id !== "firefox-default" ? (container_names[store_id] ?? "") : "";
    }

    async function refresh_active_indicators() {
      const win = await browser.windows.getLastFocused({ populate: true });
      const active = win.tabs?.find((t) => t.active);
      update_container_indicator(active?.cookieStoreId);
      update_root_indicator(active?.id);
    }

    let root_indicator_timer: ReturnType<typeof setTimeout> | undefined;
    function update_root_indicator(tab_id?: number) {
      clearTimeout(root_indicator_timer);
      root_indicator_timer = setTimeout(() => void update_root_indicator_now(tab_id), 100);
    }

    const tab_histories = new Map<number, { urls: string[]; index: number; key: string }>();

    async function entry_key(tab_id: number, url: string) {
      return await glide.content.execute(
        (url: string) => (window.navigation.entries().findLast((e) => e.url === url) ?? window.navigation.currentEntry)?.key ?? "",
        { tab_id, args: [url] },
      ).catch(() => "");
    }

    async function track_navigation(details: { tabId: number; frameId: number; url: string; transitionType: string; transitionQualifiers: string[] }, same_document: boolean) {
      if (details.frameId !== 0 || details.transitionType === "reload") {
        return;
      }
      const key = await entry_key(details.tabId, details.url);
      let entry = tab_histories.get(details.tabId);
      if (entry == null) {
        const length = await glide.content.execute(() => history.length, { tab_id: details.tabId }).catch(() => 1);
        entry = { urls: [], index: length - 1, key };
        entry.urls[entry.index] = details.url;
        tab_histories.set(details.tabId, entry);
      } else if (details.transitionQualifiers.includes("forward_back")) {
        entry.index += entry.urls[entry.index + 1] === details.url ? 1 : -1;
      } else if (same_document && key === entry.key) {
        entry.urls[entry.index] = details.url;
      } else {
        entry.urls = [...entry.urls.slice(0, entry.index + 1), details.url];
        entry.index += 1;
      }
      entry.key = key;

      const tab = await browser.tabs.get(details.tabId);
      if (tab.active) {
        update_root_indicator(details.tabId);
      }
    }

    async function update_root_indicator_now(tab_id?: number) {
      const root_el = document.getElementById("glide-statusline-root");
      if (window.closed || !root_el) {
        return;
      }
      if (tab_id == null) {
        root_el.textContent = "";
        return;
      }

      const entry = tab_histories.get(tab_id);
      const at_root = entry != null ? entry.index <= 0 : await glide.content.execute(() => history.length <= 1, { tab_id }).catch(() => true);
      root_el.textContent = at_root ? "/" : "";
    }
    glide.autocmds.create("ConfigLoaded", () => {
      browser.tabs.onCreated.addListener((tab) => {
        if (tab.id != null && (tab.url === "about:newtab" || tab.url === "about:home")) {
          tab_histories.set(tab.id, { urls: [], index: -1, key: "" });
        }
        void update_tab_count();
      });
      browser.tabs.onRemoved.addListener((tab_id) => {
        tab_histories.delete(tab_id);
        void update_tab_count();
      });
      browser.tabs.onActivated.addListener(async (info) => {
        update_root_indicator(info.tabId);
        const tab = await browser.tabs.get(info.tabId).catch(() => null);
        update_container_indicator(tab?.cookieStoreId);
      });
      browser.tabs.onUpdated.addListener((_tab_id, change, tab) => {
        if (!tab.active || change.url == null) {
          return;
        }
        update_container_indicator(tab.cookieStoreId);
      });
      browser.windows.onFocusChanged.addListener(() => {
        void refresh_active_indicators();
      });
      browser.webNavigation.onCommitted.addListener((details) => void track_navigation(details, false));
      browser.webNavigation.onHistoryStateUpdated.addListener((details) => void track_navigation(details, true));
      browser.webNavigation.onReferenceFragmentUpdated.addListener((details) => void track_navigation(details, true));
    });
  '';
}
