{
  flake.modules.homeManager.glide =
    { lib, globals, ... }:
    {
      programs.glide-browser.config = ''
        const invidious_css = css`
          body {
            max-width: 100% !important;
            margin: 0 !important;
            padding: 0 !important;
          }

          .pure-u-md-2-3,
          .pure-u-lg-2-3,
          .pure-u-md-1-3,
          .pure-u-lg-1-3 {
            width: 100% !important;
          }

          #contents,
          .pure-g,
          .pure-u-md-2-3 > .h-box,
          .pure-u-lg-2-3 > .h-box {
            max-width: 100% !important;
            width: 100% !important;
            padding-left: 0 !important;
            padding-right: 0 !important;
            margin-left: 0 !important;
            margin-right: 0 !important;
          }

          #player-container {
            width: 100% !important;
            max-width: 100% !important;
            aspect-ratio: 16 / 9;
            height: auto !important;
            padding: 0 !important;
            margin: 0 !important;
            max-height: 90vh !important;
          }

          .video-js,
          .video-js video,
          .video-js .vjs-tech,
          #player {
            width: 100% !important;
            height: 100% !important;
            padding-top: 0 !important;
          }

          #player-container + .h-box,
          #player-container + div {
            margin-top: 0.5em !important;
            padding-top: 0 !important;
          }
        `;

        glide.autocmds.create("UrlEnter", /https:\/\/${
          lib.replaceStrings [ "." ] [ "\\." ] globals.services.invidious.domain
        }\/watch/, ({ tab_id }) => {
          glide.content.execute((css_text) => {
            if (!document.getElementById("glide-user-style")) {
              const el = document.createElement("style");
              el.id = "glide-user-style";
              el.textContent = css_text;
              document.head.appendChild(el);
            }
          }, { tab_id, args: [invidious_css] });
        });
      '';
    };
}
