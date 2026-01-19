[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2FSwarsel%2F.dotfiles%2Fbadge%3Fref%3Dmain&style=flat&labelColor=11111b)](https://actions-badge.atrox.dev/Swarsel/.dotfiles/goto?ref=main)

  ###### Disclaimer

  You probably do not want to use this setup verbatim. This is made to fit my specific use cases, and I do not guarantee best practises everywhere. Changes are made on a daily basis.

  That being said, there is a lot of general configuration that you *probably* can use without changes; if you only want to use this repository as a starting point for your own configuration, you should be fine. See below for more information. Also, if you see something that can be done more efficiently or better in general, please let me know! :)

  # \~SwarselSystems\~

  <p align="center">
    <img width="49%" title="Tiling" alt="swarselsystems_preview1" src="https://github.com/user-attachments/assets/f6021ab9-6289-497d-8747-28f5d526b75a" />
    <img width="49%" title="Waybar" alt="swarselsystems_preview2" src="https://github.com/user-attachments/assets/1160d9f7-710c-4046-8fcf-476bb4a0be84" />
  </p>

  ## Overview

  - [Literate configuration](https://swarsel.github.io/.dotfiles/) defining my entire infrastructure, including Emacs
  - Configuration based on flakes for personal hosts as well as servers on:
    - [NixOS](https://github.com/NixOS/nixpkgs)
    - [home-manager](https://github.com/nix-community/home-manager) only (no full NixOS) with support from [nixGL](https://github.com/nix-community/nixGL)
    - [nix-darwin](https://github.com/LnL7/nix-darwin)
    - [nix-on-droid](https://github.com/nix-community/nix-on-droid)
  - Streamlined configuration and deployment pipeline:
    - Framework for [packages](https://github.com/Swarsel/.dotfiles/blob/main/nix/packages.nix), [overlays](https://github.com/Swarsel/.dotfiles/blob/main/nix/overlays.nix), [modules](https://github.com/Swarsel/.dotfiles/tree/main/modules), and [library functions](https://github.com/Swarsel/.dotfiles/blob/main/nix/lib.nix)
    - Dynamically generated config:
      - host configurations
      - dns records
      - network setup (+ wireguard mesh on systemd-networkd)
    - Remote Builders for [x86_64,aarch64]-linux running in hydra, feeding a private nix binary cache
    - Bootstrapping:
      - Limited local installer (no secrets handling) with a supported demo build
      - Fully autonomous remote deployment using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and [disko](https://github.com/nix-community/disko) (with secrets handling)
    - Improved nix tooling
  - Support for advanced features:
    - Secrets handling using [sops-nix](https://github.com/Mic92/sops-nix) (pls no pwn ❤️)
    - Management of personally identifiable information using [nix-plugins](https://github.com/shlevy/nix-plugins)
    - Full Yubikey support
    - LUKS-encryption with support for remote disk unlock over SSH
    - Secure boot using [Lanzaboote](https://github.com/nix-community/lanzaboote)
    - BTRFS-based [Impermanence](https://github.com/nix-community/impermanence)
    - Configuration shared between configurations (configuration for one nixosConfiguration can be defined in another nixosConfiguration)
    - Global attributes shared between all configurations to reduce attribute redeclaration
    - [Config library](https://github.com/Swarsel/.dotfiles/blob/9acfc5f93457ec14773cc0616cab616917cc8af5/modules/shared/config-lib.nix#L4) for defining config-based functions for generating service information
    - Reduced friction between full NixOS- and home-manager-only deployments regarding secrets handling and config sharing

  ## Documentation

  The full documentation can be found here:

  [SwarselSystems literate configuration](https://swarsel.github.io/.dotfiles/)

  I went to great lengths in order to document the full design process of my infrastructure properly; the above document strives to serve as an introductory lecture to nix / NixOS while at the same time explaining the config in general.

  If you only came here for my Emacs configuration, the relevant files are here:

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
  Please keep in mind that this limited installer will make local changes to the cloned repository in order to be able to install it (otherwise the builder would fail at fetching my private secrets repository). As such, this should only be used to evaluate the system - if you want to use it longterm, you will need to create a fork and make some changes.
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
  5) That should be it! The installer will take care of setting up disks, secrets, and the rest of the hardware configuration! You will still have to sign in manually to some webservices etc.

  #### Local deployment (recommended for setting up the first system)

  1) Boot the latest install ISO from this repository on an UEFI system.
  2) Run `swarsel-install -n <CONFIGURATION_NAME>`
  3) Reboot

  Alternatively, to install this from any NixOS live ISO, run `nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles#install -- -n <CONFIGURATION_NAME>` at step 2.
  </details>

  ## Infrastructure

  <details>
    <summary>Click here for a summary of my infrastructure</summary>

<img width="4176" height="8367" alt="topology" src="https://github.com/user-attachments/assets/8b7f148d-8e49-4788-ba0f-4487482a483b" />

  ### Programs

  | Topic         | Program                                                                                                                     |
  |---------------|-----------------------------------------------------------------------------------------------------------------------------|
  |🐚 **Shell**   | [zsh](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/zsh.nix)                                           |
  |🚪 **DM**      | [greetd](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/common/login.nix)                                     |
  |🪟 **WM**      | [SwayFX](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/sway.nix)                                       |
  |⛩️ **Bar**     | [Waybar](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/waybar.nix)                                     |
  |✒️ **Editor**  | [Emacs](https://github.com/Swarsel/.dotfiles/tree/main/files/emacs/init.el)                                                 |
  |🖥️ **Terminal**| [Kitty](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/kitty.nix)                                       |
  |🚀 **Launcher**| [Fuzzel](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/fuzzel.nix)                                     |
  |🚨 **Alerts**  | [Mako](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/mako.nix)                                         |
  |🌐 **Browser** | [Firefox](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/zsh.nix)                                       |
  |🎨 **Theme**   | [City-Lights (managed by stylix)](https://github.com/Swarsel/.dotfiles/tree/main/modules/home/common/sharedsetup.nix)       |

  ### Services

  | Topic                      | Program                                                                                                        |
  |------------------------------|----------------------------------------------------------------------------------------------------------------|
  |📖 **Books**                | [Kavita](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/kavita.nix)                       |
  |📼 **Videos**               | [Jellyfin](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/jellyfin.nix)                   |
  |🎵 **Music**                | [Navidrome](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/navidrome.nix) +  [Spotifyd](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/spotifyd.nix) +  [MPD](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/mpd.nix)                                                              |
  |🗨️ **Messaging**            | [Matrix](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/matrix.nix)                       |
  |📁 **Filesharing**          | [Nectcloud](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/nextcloud.nix)                 |
  |🎞️ **Photos**               | [Immich](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/immich.nix)                       |
  |📄 **Documents**            | [Paperless](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/paperless.nix)                 |
  |🔄 **File Sync**            | [Syncthing](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/syncthing.nix)                 |
  |💾 **Backups**              | [Restic](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/restic.nix)                       |
  |👁️ **Monitoring**           | [Grafana](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/monitoring.nix)                  |
  |🍴 **RSS**                  | [FreshRss](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/freshrss.nix)                   |
  |🌳 **Git**                  | [Forgejo](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/forgejo.nix)                     |
  |⚓ **Anki Sync**            | [Anki Sync Server](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/ankisync.nix)                      |
  |🪪 **SSO**                  | [Kanidm](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/kanidm.nix) + [oauth2-proxy](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/oauth2-proxy.nix)           |
  |💸 **Finance**              | [Firefly-III](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/firefly-iii.nix)             |
  |🃏 **Collections**          | [Koillection](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/koillection.nix)             |
  |🗃️ **Shell History**        | [Atuin](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/atuin.nix)                         |
  |📅 **CalDav/CardDav**       | [Radicale](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/radicale.nix)                   |
  |↔️ **P2P Filesharing**      | [Croc](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/croc.nix)                           |
  |✂️ **Paste Tool**           | [Microbin](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/microbin.nix)                   |
  |📸 **Image Sharing**        | [Slink](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/slink.nix)                         |
  |🔗 **Link Shortener**       | [Shlink](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/shlink.nix)                       |
  |⛏️ **Minecraft**            | [Minecraft](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/minecraft.nix)                 |
  |☁️ **S3**                   | [Garage](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/garage.nix)                       |
  |🕸️ **Nix Binary Cache**     | [Attic](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/attic.nix)                         |
  |🐙 **Nix Build farm**       | [Attic](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/hydra.nix)                         |
  |🔑 **Cert-based SSH**       | [OPKSSH](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/opkssh.nix)                       |
  |🔨 **Home Asset Management**| [Homebox](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/homebox.nix)                     |
  |👀 **DNS Records**          | [NSD](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/nsd.nix)                             |
  |✉️ **Mail**                 | [simple-nixos-mailserver](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/mailserver.nix)  |
  |🚇 **VPN Access**           | [Firezone](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/firezone.nix)                   |
  |🛡️ **Local DNS Resolver**   | [AdGuard Home](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/adguardhome.nix)                     |
  |🛎️ **DHCP**                 | [Kea](https://github.com/Swarsel/.dotfiles/tree/main/modules/nixos/server/kea.nix)                             |

  ### Hosts

  | Name                | Hardware                                            | Use                                                             |
  |---------------------|-----------------------------------------------------|-----------------------------------------------------------------|
  |💻 **pyramid**       | Framework Laptop 16, AMD 7940HS, RX 7700S, 64GB RAM | Work laptop                                                     |
  |💻 **bakery**        | Lenovo Ideapad 720S-13IKB                           | Personal laptop                                                 |
  |💻 **machpizza**     | MacBook Pro 2016                                    | MacOS reference and build sandbox                               |
  |🏠 **treehouse**     | NVIDIA DGX Spark                                    | AI Workstation, remote builder, hm-only-reference               |
  |🖥️ **summers**       | ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM  | Homeserver (microvms), remote builder, data storage             |
  |🖥️ **winters**       | ASRock J4105-ITX, 32GB RAM                          | Homeserver (IoT server in spe)                                  |
  |🖥️ **hintbooth**     | HUNSN RM02, 8GB RAM                                 | Router, DNS Resolver, home NGINX endpoint                       |
  |☁️ **stoicclub**     | Cloud Server: 1 vCPUs, 8GB RAM                      | Authoritative DNS server                                        |
  |☁️ **liliputsteps**  | Cloud Server: 1 vCPUs, 8GB RAM                      | SSH bastion                                                     |
  |☁️ **twothreetunnel**| Cloud Server: 2 vCPUs, 8GB RAM                      | Service proxy                                                   |
  |☁️ **eagleland**     | Cloud Server: 2 vCPUs, 8GB RAM                      | Mailserver                                                      |
  |☁️ **moonside**      | Cloud Server: 4 vCPUs, 24GB RAM                     | Game servers, syncthing + other lightweight services            |
  |☁️ **belchsfactory** | Cloud Server: 4 vCPUs, 24GB RAM                     | Hydra builder and nix binary cache                              |
  |🪟 **chaostheater**  | Asus Z97-A, i7-4790k, GTX970, 32GB RAM              | Home Game Streaming Server (Windows/AtlasOS, not nix-managed)   |
  |📱 **magicant**      | Samsung Galaxy Z Flip 6                             | Phone                                                           |
  |💿 **drugstore**     | -                                                   | NixOS-installer ISO for bootstrapping new hosts                 |
  |💿 **brickroad**     | -                                                   | Kexec tarball for bootstrapping low-memory machines             |
  |❔ **hotel**         | -                                                   | Demo config for checking out this configuration                 |
  |❔ **toto**          | -                                                   | Helper configuration for testing purposes                       |
  </details>

  ## General Nix tips & useful links

  <details>
    <summary>Click here for a summary of nix tips & links</summary>

  - Below is a small list of tips that should be helpful if you are new to the nix ecosystem:

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
    - you can have a quick cli evaluation for nix commands with e.g. `nixpgks.lib` available using `nix-instantiate --strict --eval --expr "let lib = import <nixpkgs/lib>; in <expression>"`.
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
    - [Alan Pearce](https://alanpearce.eu/)'s nix-darwin search: https://searchix.alanpearce.eu/options/darwin/search (which supports all of the other versions as well :o)
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
      - or the [Zero to Nix series](https://zero-to-nix.com/)
      - Practical nix flakes article: https://serokell.io/blog/practical-nix-flakes
    - A bit on Overlays:
      - Overview on overlays: [Mastering Nixpkgs overlays article](https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/)
      - Some examples on best practises: [Do's and Don'ts of overlays](https://flyingcircus.io/news/detailsansicht/nixos-the-dos-and-donts-of-nixpkgs-overlays)
      - Blog article about overrides: https://bobvanderlinden.me/customizing-packages-in-nix/#using-modified-packages
    - Also useful is the [official NixOS Wiki](https://wiki.nixos.org/wiki/NixOS_Wiki)
      - there is also the [unofficial NixOS Wiki](https://nixos.wiki/) that tends to be a bit outdated, use with care
  - Some resources for specific nix tools:
    - Flake output reference: https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/outputs
    - You can find public repositories with modules at https://nur.nix-community.org/ (you should check what you are installing however):
      - I like to use this for rycee's firefox extensions: https://nur.nix-community.org/repos/rycee/
    - List of nerdfonts: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
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

  ## Attributions, Acknowledgements, Inspirations, etc.

  These are in random order (also known as 'the order in which I discovered them'). I would like to express my gratitude to:

  <details>
    <summary>The great people who have contributed code for the nix-community, with special mentions for (this list is unfairly incomplete)</summary>

  - [guibou](https://github.com/guibou/)
  - [rycee](https://github.com/rycee)
  - [adisbladis](https://github.com/adisbladis)
  - [Mic92](https://github.com/Mic92/sops-nix)
  - [lassulus](https://github.com/lassulus)
  - [danth](https://github.com/danth/)
  - [LnL7](https://github.com/LnL7)
  - [t184256](https://github.com/t184256)
  - [bennofs](https://github.com/bennofs)
  - [Pandapip1](https://github.com/Pandapip1)
  - [zowoq](https://github.com/zowoq)
  - [numtide](https://github.com/numtide)
  - [hsjobeki](https://github.com/hsjobeki)
  - [blitz](https://github.com/blitz)
  - [RaitoBezarius](https://github.com/RaitoBezarius)
  - [nikstur](https://github.com/nikstur)
  - [talyz](https://github.com/talyz)
  - [infinisil](https://github.com/infinisil)
  - [zhaofengli](https://github.com/zhaofengli)
  - [Artturin](https://github.com/Artturin)
  - [oddlama](https://github.com/oddlama)
  </details>

  <details>
    <summary>The people who have inspired me with their configurations (sadly also highly incomplete)</summary>

  - [theSuess](https://github.com/theSuess) with their [home-manager](https://code.kulupu.party/thesuess/home-manager)
  - [hlissner](https://github.com/hlissner) with their [dotfiles](https://github.com/hlissner/dotfiles)
  - [drduh](https://github.com/drduh/YubiKey-Guide) with their [YubiKey-Guide](https://github.com/drduh/YubiKey-Guide)
  - [AntonHakansson](https://github.com/AntonHakansson) with their [nixos-config](https://github.com/AntonHakansson/nixos-config?tab=readme-ov-file)
  - [Guekka](https://github.com/Guekka/) with their [blog](https://guekka.github.io/)
  - [NotAShelf](https://github.com/NotAShelf) with their [nyx](https://github.com/NotAShelf/nyx)
  - [Misterio77](https://github.com/Misterio77) with their [nix-config](https://github.com/Misterio77/nix-config)
  - [0xdade](https://github.com/0xdade) with their [blog](https://0xda.de/blog/)
  - [EmergentMind](https://github.com/EmergentMind) with their [nix-config](https://github.com/EmergentMind/nix-config)
  - [librephoenix](https://github.com/librephoenix) with their [nixos-config](https://github.com/librephoenix/nixos-config)
  - [Xe](https://github.com/Xe) with their [blog](https://xeiaso.net/blog/)
  - [oddlama](https://github.com/oddlama) with their [nix-config](https:/github.com/oddlama/nix-config)
  </details>

  If you feel that I forgot to pay you tribute for code that I used in this repository, please shoot me a message and I will fix it :)
