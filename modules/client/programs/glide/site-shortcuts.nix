{
  flake.modules.homeManager.glide = { globals, ... }: {
    programs.glide-browser.config = ''
      async function tab_or_tabopen(query: string) {
        const url = query.includes("://") ? query : `https://''${query}`;
        const tabs = await browser.tabs.query({ currentWindow: true });
        const existing = tabs.find((t) => t.url != null && t.url.includes(query));
        if (existing?.id != null) {
          await browser.tabs.update(existing.id, { active: true });
          return;
        }
        const { store } = await active_tab_info();
        const rule = store == null ? null : match_rule(url);
        if (rule != null && container_stores[rule.container] == null) {
          await refresh_container_stores();
        }
        const target = rule != null ? container_stores[rule.container] : undefined;
        const created = await browser.tabs.create({ url, cookieStoreId: target ?? store });
        if (rule != null && target != null && created.id != null) {
          placed.set(created.id, rule.container);
        }
      }

      function add_site_shortcuts(shortcuts: Record<string, string>) {
        for (const [keys, target] of Object.entries(shortcuts)) {
          glide.keymaps.set("normal", keys, () => tab_or_tabopen(target), {
            description: `Focus or open ''${target}`,
          });
        }
      }

      add_site_shortcuts({
        ghc: "github.com/orgs/CLIP-HPC/repositories",
        ghd: "github.com/Swarsel/.dotfiles",
        ghi: "https://github.com/issues/assigned?q=is%3Aissue%20state%3Aopen%20archived%3Afalse%20(assignee%3A%40me%20OR%20author%3A%40me)%20sort%3Aupdated-desc",
        ghni: "github.com/NixOS/nixpkgs/issues",
        ghnp: "github.com/NixOS/nixpkgs/pulls",
        ghp: "https://github.com/pulls",
        ghv: "github.com/orgs/vbc-it/repositories",
        gpd: "discourse.nixos.org/",
        gpi: "instagram.com",
        gpp: "parkour.wien/categories",
        gprn: "www.reddit.com/r/NixOS/",
        gsF: "${globals.services.freshrss.domain}",
        gsG: "${globals.services.forgejo.domain}",
        gsK: "${globals.services.kavita.domain}",
        gsM: "${globals.services.mealie.domain}",
        gsN: "${globals.services.nextcloud.domain}",
        gsSh: "${globals.services.shlink.domain}",
        gsSl: "${globals.services.slink.domain}",
        gsSx: "${globals.services.searx.domain}",
        gsSy1: "${globals.services.syncthing-moonside.domain}",
        gsSy2: "${globals.services.syncthing-summers-storage.domain}",
        gsb: "${globals.services.buildbot.domain}",
        gsc: "${globals.services.copyparty.domain}",
        gsf: "${globals.services.firefly-iii.domain}",
        gsg: "${globals.services.grafana.domain}",
        gsh: "${globals.services.homebox.domain}",
        gsi: "${globals.services.immich.domain}",
        gsj: "${globals.services.jellyfin.domain}",
        gsk: "${globals.services.koillection.domain}",
        gsm: "${globals.services.microbin.domain}",
        gsn: "${globals.services.navidrome.domain}",
        gsp: "${globals.services.paperless.domain}",
        gss: "${globals.services.shopservatory.domain}",
        gst: "${globals.services.transmission.domain}",
        gsy: "${globals.services.invidious.domain}",
      });
    '';
  };
}
