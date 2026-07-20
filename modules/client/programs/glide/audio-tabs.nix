{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
    glide.keymaps.set("normal", "<leader>A", async () => {
      const audible = await browser.tabs.query({ audible: true });
      if (audible.length === 0) {
        flash_message("no audible tabs");
        return;
      }
      await glide.commandline.show({
        title: "Audible tabs",
        options: audible.map((tab) => ({
          label: tab.title ?? tab.url ?? String(tab.id),
          description: tab.url ?? "",
          execute: async () => {
            if (tab.windowId != null) {
              await browser.windows.update(tab.windowId, { focused: true });
            }
            if (tab.id != null) {
              await browser.tabs.update(tab.id, { active: true });
            }
          },
        })),
      });
    }, { description: "Jump to a tab that is playing audio" });
  '';
}
