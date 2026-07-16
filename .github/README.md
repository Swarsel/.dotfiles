<h1 id="header" align="center">
    <img width="150" height="140" alt="nixos logo using earthbound giant step icon" src="https://github.com/Swarsel/.dotfiles/blob/main/files/icons/logo.svg" />
    <br>
    &emsp;&emsp;
    ~SwarselSystems~
    <sup><sub><sup><sub><i>(née .dotfiles)</i></sub></sup></sub></sup>
  </h1>

  <p align="center">
    <i>"With NixOS, your <a href="https://github.com/user-attachments/assets/58742580-fb02-4b51-978a-364f5df1ddbd">entire system</a> is just one file: <code>/etc/nixos/configuration.nix</code>!"</i><br>
    ... I took that <i><a href="https://swarsel.github.io/.dotfiles/">literally</a></i>.
  </p>

  <p align="center">
    <img width="49%" alt="screenshot showing emacs and glide" src="https://github.com/user-attachments/assets/3e5874be-ab3a-4cc5-88aa-28a8032799a7" />
    <img width="49%" alt="screenshot showing fastfetch and music player" src="https://github.com/user-attachments/assets/1a329b72-d404-49cb-8873-4de6a684d1cf" />
    <img width="49%" alt="screenshot showing noctalia bar" src="https://github.com/user-attachments/assets/394ff2ca-859b-4886-9125-2cf64d68f2ea" />
    <img width="49%" alt="screenshot showing wallpaper" src="https://github.com/user-attachments/assets/824a4fab-5d47-4468-859d-d59f9e0982c5" />
  </p>

  ## Overview

  - [Literate configuration](https://swarsel.github.io/.dotfiles/) defining my entire infrastructure, including Emacs
  - Dendritic configuration based on flakes (using flake-file) for personal hosts as well as servers on:
    - [NixOS](https://github.com/NixOS/nixpkgs)
    - [home-manager](https://github.com/nix-community/home-manager) only (no full NixOS) with support from [nixGL](https://github.com/nix-community/nixGL)
    - [nix-darwin](https://github.com/LnL7/nix-darwin)
    - [nix-on-droid](https://github.com/nix-community/nix-on-droid)
  - Streamlined configuration and deployment pipeline:
    - Framework for [packages](https://github.com/Swarsel/.dotfiles/blob/main/modules/flake/packages.nix), [overlays](https://github.com/Swarsel/.dotfiles/blob/main/modules/flake/overlays.nix), [dendritic modules (features)](https://github.com/Swarsel/.dotfiles/tree/main/modules), and [library functions](https://github.com/Swarsel/.dotfiles/blob/main/modules/flake/lib.nix)
    - Dynamically generated config:
      - host configurations
      - dns records
      - network setup (+ WireGuard mesh on systemd-networkd)
    - Remote Builders for `[x86_64,aarch64]-linux` running on Buildbot, feeding a private nix binary cache and updating the flake on a weekly basis
    - Bootstrapping:
      - Limited local installer (no secrets handling) with a (kinda un-)supported demo build
      - Fully autonomous remote deployment using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and [disko](https://github.com/nix-community/disko) (with secrets handling)
    - Improved nix tooling
  - Support for advanced features:
    - Secrets handling using [sops-nix](https://github.com/Mic92/sops-nix) (pls no pwn ❤️)
    - Management of personally identifiable information using [nix-plugins](https://github.com/shlevy/nix-plugins)
    - Full Yubikey support (with SSH support for SK keys, certs and PGP keys)
    - LUKS-encryption with support for remote disk unlock over SSH
    - Secure boot using [Lanzaboote](https://github.com/nix-community/lanzaboote)
    - BTRFS-based [Impermanence](https://github.com/nix-community/impermanence)
    - Configuration shared between configurations (configuration for one nixosConfiguration can be defined in another nixosConfiguration)
    - Global attributes shared between all configurations to reduce attribute re-declaration
    - [Config library](https://github.com/Swarsel/.dotfiles/blob/9acfc5f93457ec14773cc0616cab616917cc8af5/modules/shared/config-lib.nix#L4) for defining config-based functions for generating service information
    - Reduced friction between full NixOS- and home-manager-only deployments
      - efficient secrets handling depending on system context
      - automatic config sharing between contexts
      - dendritic structure for keeping features in a centralized manner

  ## Infrastructure

  <details>
    <summary>Click here for a summary of my infrastructure</summary>

<img alt="full topology diagram" src="https://github.com/Swarsel/.dotfiles/blob/main/files/topology/topology.png" />

  ### Programs


| Topic           | Program                                                                                                                                                                                              |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ⛩️ **Bar**      | [Waybar](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/waybar.nix) or [Noctalia Shell](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/noctalia.nix) |
| ✒️ **Editor**   | [Emacs](https://github.com/Swarsel/.dotfiles/tree/main/files/emacs/init.el)                                                                                                                          |
| 🌐 **Browser**  | [Firefox](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/firefox.nix)                                                                                                        |
| 🎨 **Theme**    | [City-Lights (managed by stylix)](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/stylix.nix)                                                                                 |
| 🐚 **Shell**    | [zsh](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/zsh.nix)                                                                                                                |
| 🖥️ **Terminal** | [Kitty](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/kitty.nix)                                                                                                            |
| 🚀 **Launcher** | [Fuzzel](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/fuzzel.nix) or [Noctalia Shell](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/noctalia.nix) |
| 🚨 **Alerts**   | [Mako](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/system/mako.nix) or [Noctalia Shell](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/noctalia.nix)       |
| 🚪 **DM**       | [greetd](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/system/login.nix)                                                                                                             |
| 🪟 **WM**       | [SwayFX](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/sway.nix) or [Niri](https://github.com/Swarsel/.dotfiles/tree/main/modules/client/programs/niri.nix)                 |


  ### Services


| Topic                        | Program                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ☁️ **S3**                    | [Garage](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/garage.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ⚓ **Anki Sync**             | [Anki Sync Server](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/ankisync.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ⛏️ **Minecraft**             | [Minecraft](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/minecraft.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ✂️ **Paste Tool**            | [Microbin](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/microbin.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ✉️ **Mail**                  | [simple-nixos-mailserver](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/mailserver.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| 🃏 **Collections**           | [Koillection](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/koillection.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| 🌳 **Git**                   | [Forgejo](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/forgejo.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| 🍴 **RSS**                   | [FreshRss](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/freshrss.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| 🍽️ **Recipes**               | [Mealie](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/mealie.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 🎞️ **Photos**                | [Immich](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/immich.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 🎵 **Music**                 | [Navidrome](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/navidrome.nix) +  [Spotifyd](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/spotifyd.nix) +  [MPD](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/mpd.nix)                                                                                                                                                                                                                                                                                                                                                               |
| 🐙 **Nix Build farm**        | [Buildbot](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/buildbot.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| 🐽 **Threat Detection**      | [CrowdSec](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/crowdsec.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| 👀 **DNS Records**           | [NSD](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/nsd.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| 👁️ **Monitoring**            | [Grafana](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/grafana.nix) + [Mimir](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/mimir.nix) + [Loki](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/loki.nix) + [Tempo](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/tempo.nix) + [Alloy](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/alloy.nix) + [Pyroscope](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/pyroscope.nix) + [Gotify](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/gotify.nix) |
| 💸 **Finance**               | [Firefly-III](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/firefly-iii.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| 💾 **Backups**               | [Restic](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/restic.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| 📁 **Filesharing**           | [Nextcloud](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/nextcloud.nix) +  [CopyParty](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/copyparty.nix) +  [Croc](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/croc.nix)                                                                                                                                                                                                                                                                                                                                                           |
| 📄 **Documents**             | [Paperless](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/paperless.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| 📅 **CalDav/CardDav**        | [Radicale](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/radicale.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| 📖 **Books**                 | [Kavita](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/kavita.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 📸 **Image Sharing**         | [Slink](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/slink.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 📺 **Video Streaming**       | [Invidious](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/invidious.nix) + [Invidious Companion](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/invidious-companion.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 📼 **Videos**                | [Jellyfin](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/jellyfin.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| 🔄 **File Sync**             | [Syncthing](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/syncthing.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| 🔎 **Search Engine**         | [SearXNG](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/searx.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 🔑 **Cert-based SSH**        | [OPKSSH](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/opkssh.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| 🔗 **Link Shortener**        | [Shlink](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/shlink.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 🔨 **Home Asset Management** | [Homebox](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/homebox.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| 🕸️ **Nix Binary Cache**      | [Attic](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/attic.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| 🗃️ **Shell History**         | [Atuin](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/atuin.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 🗨️ **Messaging**             | [Matrix](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/matrix.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 🚇 **VPN Access**            | [Firezone](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/firezone.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| 🛎️ **DHCP**                  | [Kea](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/kea.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| 🛡️ **Local DNS Resolver**    | [AdGuard Home](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/adguardhome.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| 🦊 **Firefox Sync**          | [Firefox-Syncserver](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/firefox-syncserver.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| 🪎 **Second Hand Site Info** | [Shopservatory](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/shopservatory.nix) + [Socks Proxy](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/services/socks-proxy.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| 🪪 **SSO**                   | [Kanidm](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/kanidm.nix) + [oauth2-proxy](https://github.com/Swarsel/.dotfiles/tree/main/modules/server/infra/oauth2-proxy.nix)                                                                                                                                                                                                                                                                                                                                                                                                                                                             |


  ### Hosts


| Name                  | Hardware                                            | Use                                                           |
|-----------------------|-----------------------------------------------------|---------------------------------------------------------------|
| 💻 **bakery**         | Lenovo Ideapad 720S-13IKB                           | Personal laptop                                               |
| 💻 **machpizza**      | MacBook Pro 2016                                    | MacOS reference and build sandbox                             |
| 💻 **pyramid**        | Framework Laptop 16, AMD 7940HS, RX 7700S, 64GB RAM | Work laptop                                                   |
| 🏠 **treehouse**      | NVIDIA DGX Spark                                    | AI Workstation, remote builder, hm-only-reference             |
| 🖥️ **hintbooth**      | HUNSN RM02, 8GB RAM                                 | Router, DNS Resolver, home NGINX endpoint                     |
| 🖥️ **summers**        | ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM  | Homeserver (microvms), remote builder, data storage           |
| 🖥️ **winters**        | ASRock J4105-ITX, 32GB RAM                          | Homeserver (IoT server in spe)                                |
| ☁️ **belchsfactory**  | Cloud Server: 4 vCPUs, 24GB RAM                     | Hydra builder and nix binary cache                            |
| ☁️ **eagleland**      | Cloud Server: 2 vCPUs, 8GB RAM                      | Mailserver                                                    |
| ☁️ **liliputsteps**   | Cloud Server: 1 vCPUs, 8GB RAM                      | SSH bastion                                                   |
| ☁️ **moonside**       | Cloud Server: 4 vCPUs, 24GB RAM                     | Game servers, syncthing + other lightweight services          |
| ☁️ **stoicclub**      | Cloud Server: 1 vCPUs, 8GB RAM                      | Authoritative DNS server                                      |
| ☁️ **twothreetunnel** | Cloud Server: 2 vCPUs, 8GB RAM                      | Service proxy                                                 |
| 🪟 **chaostheater**   | Asus Z97-A, i7-4790k, GTX970, 32GB RAM              | Home Game Streaming Server (Windows/AtlasOS, not nix-managed) |
| 📱 **magicant**       | Samsung Galaxy Z Flip 6                             | Phone                                                         |
| 💿 **brickroad**      | -                                                   | Kexec tarball for bootstrapping low-memory machines           |
| 💿 **drugstore**      | -                                                   | NixOS-installer ISO for bootstrapping new hosts               |
| 💿 **policestation**  | -                                                   | NixOS live ISO for generating cryptographic keys              |
| ❔ **hotel**          | -                                                   | Demo config for checking out this configuration               |
| ❔ **toto**           | -                                                   | Helper configuration for deployment testing                   |
| ❔ **vacanthouse**    | -                                                   | Staging environment                                           |


  </details>


  ## Documentation

  The full documentation can be found here:

  [SwarselSystems literate configuration](https://swarsel.github.io/.dotfiles/)

  I went to great lengths in order to document the full design process of my infrastructure properly; the above document strives to serve as an introductory lecture to nix / NixOS while at the same time explaining the config in general.

  ### Emacs

  If you came here for my raw Emacs configuration, the relevant files live here in elisp form (these files are generated from the nix `emacs-init` module):

  - [early-init.el](../files/emacs/early-init.el)
  - [init.el](../files/emacs/init.el)

  ### Getting started

  #### Demo configuration

  <details>
    <summary>Click here for instructions on how to install the demo system</summary>

  If you just want to see if this configuration is for you, run this command on any system that has `nix` installed:

  ``` shell
  nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles#swarsel-rebuild -- -u <YOUR_USERNAME>
  ```

  This will activate the `hotel` configuration on your system, which is a de-facto mirror of my main configuration with secret-based settings removed.
  Since you do not have my SSH keys, the installer automatically replaces the private flake inputs (my work repository and the encrypted repository secrets) with public demo stand-ins via `--override-input` - nothing in the repository is modified for this. This should only be used to evaluate the system - if you want to use it long-term, you will need to create a fork and make some changes.
  </details>

  ### Deployment

  <details>
    <summary>Click here for deployment instructions</summary>

  The deployment process for this configuration is mostly automated, there are only a few steps that are needed to be done manually. You can choose between a remote deployment strategy that is also able to deploy new age keys for sops for you and a local installer that will only install the system without any secret handling.

  #### Remote deployment (recommended if you have at least one running system)

  0) Fork this repo, and write your own host config at `hosts/nixos/<YOUR_ARCHITECTURE>/<YOUR_CONFIG_NAME>/default.nix` (you can use one of the other configurations as a template. Also see https://github.com/Swarsel/.dotfiles/tree/main/modules for a list of all additional options). At the very least, you should replace the `secrets/` directory with your own secrets and replace the SSH public keys with your own ones (otherwise I will come visit you!🔓❤️). I personally recommend to use the literate configuration and `org-babel-tangle-file` in Emacs, but you can also simply edit the separate `.nix` files.
  1) Have a system with `nix` available booted (this does not need to be installed, i.e. you can use a NixOS installer image; a custom minimal installer ISO can be built by running `just iso` in the root of this repo)
  2) Make sure that your Yubikey is plugged in or that you have your SSH key available (and configured)
  3) Run `swarsel-bootstrap -n <CONFIGURATION_NAME> -d <TARGET_IP>` on your existing system.
    - Alternatively (if you run this on a system that is not yet running this configuration), you can also run `nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles -- -n <CONFIGURATION_NAME> -d <TARGET_IP>` (this runs the same program as the command above).
  4) Follow the installers instructions:
    - you will have to choose a disk encryption password (if you want that feature)
    - you will have to confirm once that the target system has rebooted
    - you will have to enter the root password once during the final system install
  5) That should be it! The installer will take care of setting up disks, secrets, and the rest of the hardware configuration! You will still have to sign in manually to some web services etc.

  #### Local deployment (recommended for setting up the first system)

  1) Boot the latest install ISO from this repository on an UEFI system.
  2) Run `swarsel-install -n <CONFIGURATION_NAME>`
  3) Reboot

  Alternatively, to install this from any NixOS live ISO, run `nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles#swarsel-install -- -n <CONFIGURATION_NAME>` at step 2.
  </details>

  ## Attributions, Acknowledgments, Inspirations, etc.

  I would like to express my gratitude (not solely) to:

  <details>
    <summary>The people who help maintain <a href="https://github.com/orgs/NixOS/people">NixOS</a>, <a href="https://github.com/orgs/nix-community/people">nix-community</a>, and other nix-related projects.</summary>
  </details>

  <details>
    <summary>The people who have inspired me with their configurations</summary>

  - [theSuess](https://github.com/theSuess) with their [home-manager](https://code.kulupu.party/thesuess/home-manager)
  - [hlissner](https://github.com/hlissner) with their [dotfiles](https://github.com/hlissner/dotfiles)
  - [AntonHakansson](https://github.com/AntonHakansson) with their [nixos-config](https://github.com/AntonHakansson/nixos-config?tab=readme-ov-file)
  - [EmergentMind](https://github.com/EmergentMind) with their [nix-config](https://github.com/EmergentMind/nix-config)
  - [oddlama](https://github.com/oddlama) with their [nix-config](https://github.com/oddlama/nix-config)
  </details>

  If you feel that I forgot to pay you tribute for code that I used in this repository, please shoot me a message and I will fix it :)

## FAQ

Q: <i>How do I get started with nix?</i><br>
<details><summary>A: Click here for a small list of tips that should be helpful if you are new to the nix ecosystem</summary>

  - Temporarily install any package using `nix shell nixpkgs#<PACKAGE_NAME>` - this can be e.g. useful if you accidentally removed home-manager from your packages on a non-NixOS machine.
    - if you need multiple packages, you can do `nix shell nixpkgs#{<pkg1>,<pkg2>,<pkg3>}`.
    - you can set `nix.registry` to add more flakes to your registry. I use this to add a `n` shorthand to `nixpkgs`, which allows me to do `nix shell n#{<pkg1>,<pkg2>,<pkg3>}`.
  - Alternatively, use [comma](https://github.com/nix-community/comma)
    - More info on `nix [...]` commands: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix
    - some examples:
      - `nix flake update <input-name>` lets you update a specific input only.
      - `nix repl <your flake path>` gives quick insight into your written configuration.
      - `nix eval <your flake path>#<config attribute>` quickly returns an attribute in your written configuration
      - `nix fmt` formats your flake using the formatter specified under `formatter` in your `flake.nix`
  - When you are trying to setup a new configuration part, [GitHub code search](https://github.com/search?q=language%3ANix&type=code) can really help you to find a working configuration. Just filter for `.nix` files and the options you are trying to set up.
  - getting packages at a different version than your target (or not packaged at all) can be done in most cases easily with fetchFromGithub (https://ryantm.github.io/nixpkgs/builders/fetchers/)
  - you can easily install old revisions of packages using https://lazamar.co.uk/nix-versions/. You can conveniently spawn a shell with a chosen package available using `vershell <NIXPKGS_REVISION> <PACKAGE>`. Just make sure to pick a revision that has flakes enabled, otherwise you will need the legacy way of spawning the shell (see the link for more info)
  - when developing modules in a dev branch of another flake, you can use `--override-input` to temporarily use the local directory as the flake source.
  - including `nixosConfig ? config` in your module arguments is a smart way of enabling a module to pull in config from NixOS or home-manager config, no matter if it is a NixOS system or not.
  - you can have a quick CLI evaluation for nix commands with e.g. `nixpgks.lib` available using `nix-instantiate --strict --eval --expr "let lib = import <nixpkgs/lib>; in <expression>"`.
  - if you are looking for a specific library, `nix-locate` makes it easy to look for them.
  - to look at the dependencies pulled in by a tool, use `nix-tree`
    - to find out which derivation uses another derivation, use `nix store --query --referrers <derivation>`
  - to get a neat overview of your config changes in recent generations, use `nix profile diff-closures --profile /nix/var/nix/profiles/system`
    - to get instead the changes since the last boot, use `nix profile diff-closures /run/*-system`
    - if you just need the generation numbers, use `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`
    - to then switch to another generation, you can use `sudo nix-env --switch-generation <generation number> -p /nix/var/nix/profiles/system` followed by `sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch`

  - These links are your best friends:
    - The nix documentation: https://nix.dev/
    - The nixpkgs reference manual: https://nixos.org/manual/nixpkgs/unstable/#buildpythonapplication-function
      - the [nixpkgs repository](https://github.com/NixOS/nixpkgs) - especially useful to look at the various READMEs that are in various places in the repository (find using GitHub code search) as well as the [issues](https://github.com/Swarsel/.dotfiles/issues) and [PRs](https://github.com/Swarsel/.dotfiles/pulls) pages
      - and the [nixpkgs Pull Request Tracker](https://nixpk.gs/pr-tracker.html)
    - The NixOS manual: https://nixos.org/manual/nixos/stable/
    - The NixOS package search: https://search.nixos.org/packages
      - and the nix package version search: https://lazamar.co.uk/nix-versions/
    - The NixOS option search https://search.nixos.org/options
    - [mipmip](https://github.com/mipmip)'s home-manager option search: https://mipmip.github.io/home-manager-option-search/
    - [Alan Pearce](https://alanpearce.eu/)'s `nix-darwin` search: https://searchix.alanpearce.eu/options/darwin/search (which supports all of the other versions as well :o)
    - For the above, you can use the CLI tool [manix](https://github.com/mlvzk/manix)
    - Nix function search: https://noogle.dev/
    - Search for nix-community options: https://search.nüschtos.de/
  - But that is not all:
    - Some nix resources
      - A tour of Nix: https://nixcloud.io/tour/
      - The Nix One Pager: https://github.com/tazjin/nix-1p
      - another one page introduction: https://learnxinyminutes.com/nix/
      - a very short introduction to Nix features: https://zaynetro.com/explainix
      - introductory nix article: https://medium.com/@MrJamesFisher/nix-by-example-a0063a1a4c55
      - and another one: https://web.archive.org/web/20210121042658/https://ebzzry.io/en/nix/#nix
      - How to learn nix: https://ianthehenry.com/posts/how-to-learn-nix/
      - the Nix Cookbook: https://github.com/functionalops/nix-cookbook?tab=readme-ov-file
      - and the Nix Pills: https://nixos.org/guides/nix-pills/
    - Some resources on flakes
      - Why to use flakes and introduction to flakes: https://www.tweag.io/blog/2020-05-25-flakes/
      - The [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
      - and [Wombat's book](https://mhwombat.codeberg.page/nix-book/)
      - as well as [Ekala's book](https://ekala-project.github.io/nix-book/)
      - or the [Zero to Nix series](https://zero-to-nix.com/)
      - last but not least, [NixOS in Production](https://leanpub.com/nixos-in-production)
      - Practical nix flakes article: https://serokell.io/blog/practical-nix-flakes
    - A bit on Overlays:
      - Overview on overlays: [Mastering Nixpkgs overlays article](https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/)
      - Some examples on best practices: [Do's and Don'ts of overlays](https://flyingcircus.io/news/detailsansicht/nixos-the-dos-and-donts-of-nixpkgs-overlays)
      - Blog article about overrides: https://bobvanderlinden.me/customizing-packages-in-nix/#using-modified-packages
    - Also useful is the [official NixOS Wiki](https://wiki.nixos.org/wiki/NixOS_Wiki)
      - there is also the [unofficial NixOS Wiki](https://nixos.wiki/) that tends to be a bit outdated, use with care
  - Some resources for specific nix tools:
    - Flake output reference: https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/outputs
    - You can find public repositories with modules at https://nur.nix-community.org/ (you should check what you are installing however):
      - I like to use this for rycee's Firefox extensions: https://nur.nix-community.org/repos/rycee/
    - List of nerd-fonts: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    - Stylix configuration options: https://danth.github.io/stylix/
    - nix-on-droid options: https://nix-community.github.io/nix-on-droid/nix-on-droid-options.html#sec-options
  - Very useful tools that are mostly not directly used in configuration but instead called on need:
    - Convert non-NixOS machines to NixOS using [nixos-infect](https://github.com/elitak/nixos-infect)
    - Create various installation media with [nixos-generators](https://github.com/nix-community/nixos-generators)
    - Remotely deploy NixOS using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
  - And a few links that are not directly nix-related, but may still serve you well:
    - List of pre-commit-hooks: https://devenv.sh/reference/options/#pre-commithooks
    - Waybar configuration: https://github.com/Alexays/Waybar/wiki

 </details>

<br>

Q: <i>Why Is this just called `.dotfiles`?</i><br>
<details><summary>A: Would you rename your children once they turn 18?</summary></details>
