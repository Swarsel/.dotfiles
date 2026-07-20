{
  flake.modules.homeManager.glide.programs.glide-browser.config = ''
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
    });'';
}
