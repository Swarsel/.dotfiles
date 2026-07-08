{
  flake.modules.homeManager.glide =
    { config, ... }:
    {
      programs.glide-browser.config = ''
        interface Heading {
          text: string;
          level: number;
          xpath: string;
        }

        glide.keymaps.set("normal", "<leader>h", async () => {
          const tab_id = (await glide.tabs.active()).id;

          const headings = await glide.content.execute((): Heading[] => {
            function is_visible(el: HTMLElement): boolean {
              const style = window.getComputedStyle(el);
              return (
                style.display !== "none" &&
                style.visibility !== "hidden" &&
                style.opacity !== "0" &&
                el.offsetParent !== null
              );
            }
            function xpath_for(node: Element): string {
              let path = "";
              for (let el: Element | null = node; el; el = el.parentElement) {
                let index = 0;
                for (let sib = el.previousElementSibling; sib; sib = sib.previousElementSibling) {
                  if (sib.tagName === el.tagName) index++;
                }
                path = "/" + el.tagName.toLowerCase() + "[" + (index + 1) + "]" + path;
              }
              return path;
            }
            return Array.from(document.querySelectorAll("h1, h2, h3, h4, h5, h6"))
              .filter((el) => is_visible(el as HTMLElement))
              .map((el) => ({
                text: (el.textContent ?? "").trim(),
                level: Number(el.tagName[1]),
                xpath: xpath_for(el),
              }))
              .filter((h) => h.text !== "");
          }, { tab_id });

          if (headings.length === 0) {
            flash_message("no headings found");
            return;
          }

          await glide.commandline.show({
            title: "Jump to heading",
            options: headings.map((heading) => ({
              label: "  ".repeat(heading.level - 1) + heading.text,
              execute: async () => {
                await glide.content.execute((xpath: string, color: string) => {
                  const target = document.evaluate(
                    xpath,
                    document,
                    null,
                    XPathResult.FIRST_ORDERED_NODE_TYPE,
                    null,
                  ).singleNodeValue as HTMLElement | null;
                  if (!target) return;
                  target.scrollIntoView({ behavior: "smooth", block: "start" });
                  const previous = target.style.outline;
                  target.style.outline = "2px solid " + color;
                  setTimeout(() => {
                    target.style.outline = previous;
                  }, 2000);
                }, { tab_id, args: [heading.xpath, "${config.lib.stylix.colors.withHashtag.base09}"] });
              },
            })),
          });
        }, { description: "Jump to a heading on the current page" });
      '';
    };
}
