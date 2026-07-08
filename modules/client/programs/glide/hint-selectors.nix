{
  flake.modules.homeManager.glide = {
    programs.glide-browser.config = ''
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
    '';
  };
}
