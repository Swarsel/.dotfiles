{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    function enforce_input_mode() {
      if (glide.ctx.mode === "normal" && glide.findbar.is_focused()) {
        void glide.excmds.execute("mode_change insert");
      }
    }

    glide.autocmds.create("ModeChanged", "*:normal", enforce_input_mode);

    let enforce_timer: ReturnType<typeof setInterval> | null = null;
    function stop_enforce_polling() {
      if (enforce_timer != null) {
        clearInterval(enforce_timer);
        enforce_timer = null;
      }
    }
    function start_enforce_polling() {
      if (enforce_timer != null) {
        return;
      }
      enforce_timer = setInterval(() => {
        if (!glide.findbar.is_open()) {
          stop_enforce_polling();
          return;
        }
        enforce_input_mode();
      }, 100);
    }

    async function open_findbar() {
      await glide.findbar.open({ query: "" });
      start_enforce_polling();
    }

    glide.keymaps.set("normal", "/", open_findbar);
    glide.keymaps.set("normal", "?", open_findbar);
    glide.keymaps.set("normal", "n", async () => {
      await glide.findbar.next_match();
      start_enforce_polling();
    });
    glide.keymaps.set("normal", "N", async () => {
      await glide.findbar.previous_match();
      start_enforce_polling();
    });

    glide.keymaps.set(["insert", "normal", "visual", "op-pending"], "<Esc>", async () => {
      if (glide.findbar.is_open()) {
        await glide.findbar.close();
      }
      await glide.excmds.execute("blur");
      await glide.excmds.execute("mode_change normal");
    });

    glide.keymaps.set("command", "<Esc>", () => void glide.commandline.close());
  '';
}
