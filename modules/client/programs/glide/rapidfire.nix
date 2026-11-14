{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    let rapidfire = false;

    async function wait_for_page_load() {
      await new Promise((resolve) => setTimeout(resolve, 500));
      while (rapidfire && (await glide.tabs.active()).status === "loading") {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    glide.keymaps.set("normal", "q", () => {
      rapidfire = true;
      start_hints();
    });

    glide.keymaps.set("hint", "<Esc>", async () => {
      rapidfire = false;
      await glide.excmds.execute("hints_remove");
    });

    glide.autocmds.create("ModeChanged", "hint:*", async ({ new_mode }) => {
      if (!rapidfire || new_mode === "hint") {
        return;
      }

      await wait_for_page_load();
      if (!rapidfire) {
        return;
      }
      if (glide.ctx.mode !== "normal") {
        rapidfire = false;
        return;
      }
      start_hints();
    });
  '';
}
