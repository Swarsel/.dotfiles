{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
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
  '';
}
