{
  flake.modules.homeManager.glide =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.glide-browser.config = ''
        async function advertised_repo(): Promise<{ https: string; ssh: string | null } | null> {
          async function fetch_document(url: string, credentials: RequestCredentials): Promise<Document | null> {
            try {
              const response = await fetch(url, { credentials });
              return response.ok ? new DOMParser().parseFromString(await response.text(), "text/html") : null;
            } catch {
              return null;
            }
          }
          const nwo = document.querySelector('meta[name="octolytics-dimension-repository_nwo"]')?.getAttribute("content");
          let https = nwo != null && (location.pathname + "/").toLowerCase().startsWith("/" + nwo.toLowerCase() + "/") ? location.origin + "/" + nwo + ".git" : undefined;
          for (const credentials of ["omit", "include"] as const) {
            if (https != null) {
              break;
            }
            const go_get = await fetch_document(location.origin + location.pathname + "?go-get=1", credentials);
            https = go_get?.querySelector('meta[name="go-import"]')?.getAttribute("content")?.split(/\s+/)[2];
          }
          if (https == null) {
            return null;
          }
          const home = await fetch_document(https.replace(/\.git$/, ""), "include");
          const ssh = home?.querySelector("#repo-clone-ssh")?.getAttribute("data-link") ?? home?.querySelector("[data-ssh-url]")?.getAttribute("data-ssh-url") ?? null;
          return { https, ssh };
        }

        async function run(command: string, args: string[]): Promise<{ exit_code: number; output: string[] }> {
          const proc = await glide.process.spawn(command, args, { check_exit_code: false, stderr: "stdout" });
          const output = await proc.stdout.lines();
          const { exit_code } = await proc.wait();
          return { exit_code, output };
        }

        async function run_clone(url: string, dest: string, setup_remotes: boolean) {
          flash_message("cloning " + url);
          const clone = await run("${lib.getExe config.programs.git.package}", ["clone", url, dest]);
          if (clone.exit_code !== 0) {
            flash_message("clone failed: " + (clone.output.at(-1) ?? "exit code " + clone.exit_code));
            return;
          }
          const remotes = setup_remotes ? (await run("${lib.getExe pkgs.swarsel-git-remotes}", [dest])).output : [];
          flash_message(["cloned into " + dest, ...remotes.map((line) => line.replace(dest + ": ", ""))].join("; "));
        }

        async function clone_advertised_repo(dir: "Private" | "Work") {
          const repo = await glide.content.execute(advertised_repo, { tab_id: await glide.tabs.active() });
          if (repo == null) {
            flash_message("no git repository advertised on this page");
            return;
          }
          const { host, pathname } = new URL(repo.https);
          const url = repo.ssh ?? "git@" + host + ":" + pathname.slice(1);
          const dest = glide.path.home_dir + "/Documents/" + dir + "/" + pathname.split("/").pop()!.replace(/\.git$/, "");
          if (await glide.fs.exists(dest)) {
            flash_message(dest + " already exists");
            return;
          }
          await glide.commandline.show({
            title: "Clone " + url + " into " + dest + "? Type y to confirm",
            options: [{
              label: "y",
              description: "git clone " + url + " " + dest,
              matches: () => true,
              execute: ({ input }) => {
                if (input.trim() === "y") {
                  void run_clone(url, dest, dir === "Private");
                }
              },
            }],
          });
        }

        glide.keymaps.set("normal", "gcp", () => clone_advertised_repo("Private"), {
          description: "Clone the repository of this page into ~/Documents/Private",
        });
        glide.keymaps.set("normal", "gcw", () => clone_advertised_repo("Work"), {
          description: "Clone the repository of this page into ~/Documents/Work",
        });
      '';
    };
}
