[![nixos-unstable](https://img.shields.io/badge/unstable-nixos?style=flat&logo=nixos&logoColor=cdd6f4&label=NixOS&labelColor=11111b&color=b4befe)](https://github.com/NixOS/nixpkgs)
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2FSwarsel%2F.dotfiles%2Fbadge%3Fref%3Dmain&style=flat&labelColor=11111b)](https://actions-badge.atrox.dev/Swarsel/.dotfiles/goto?ref=main)

###### Disclaimer

You probably do not want to use this setup verbatim. This is made to fit my specific use cases, and I do not guarantee best practises everywhere. Changes are made on a daily basis.

That being said, there is a lot of general configuration that you *probably* can use without changes; if you only want to use this repository as a starting point for your own configuration, you should be fine. See below for more information. Also, if you see something that can be done more efficiently or better in general, please let me know! :)

# \~SwarselSystems\~

<p align="center">
  <img src="https://i.imgur.com/bmgLNcu.png" width="49%" title="Tiling">
  <img src="https://i.imgur.com/0G7Be6e.png" width="49%" title="Waybar">
</p>

|               |                                 |
|---------------|---------------------------------|
| **Shell:**    | zsh                             |
| **DM:**       | greetd                          |
| **WM:**       | SwayFX                          |
| **Bar:**      | Waybar                          |
| **Editor:**   | Emacs                           |
| **Terminal:** | kitty                           |
| **Launcher:** | fuzzel                          |
| **Alerts:**   | mako                            |
| **Browser:**  | firefox                         |
| **Theme:**    | city-lights (managed by stylix) |

## Overview

- Literate configuration for Nix and Emacs ([SwarselSystems.org](../SwarselSystems.org))
- Configuration based on flakes for personal hosts as well as servers on:
  - [NixOS](https://github.com/NixOS/nixpkgs)
  - [home-manager](https://github.com/nix-community/home-manager) only (no full NixOS) with support from [nixGL](https://github.com/nix-community/nixGL)
  - [nix-darwin](https://github.com/LnL7/nix-darwin)
  - [nix-on-droid](https://github.com/nix-community/nix-on-droid)
- Streamlined configuration and deployment pipeline:
  - Framework for [packages](https://github.com/Swarsel/.dotfiles/blob/main/pkgs/default.nix), [overlays](https://github.com/Swarsel/.dotfiles/blob/main/overlays/default.nix), and [modules](https://github.com/Swarsel/.dotfiles/tree/main/modules)
  - Dynamically generated host configurations
  - Limited local installer (no secrets handling) with a supported demo build
  - Fully autonomous remote deployment using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and [disko](https://github.com/nix-community/disko) (with secrets handling)
  - Improved nix tooling
- Support for advanced features:
  - Secrets handling using [sops-nix](https://github.com/Mic92/sops-nix) (pls no pwn ❤️)
  - Management of non-file-based secrets using private repo
  - Full Yubikey support
  - LUKS-encryption
  - Secure boot using [Lanzaboote](https://github.com/nix-community/lanzaboote)
  - BTRFS-based [Impermanence](https://github.com/nix-community/impermanence)


## Documentation

If you are mainly interested in how I configured this system, check out this page:

[SwarselSystems literate configuration](https://swarsel.github.io/.dotfiles/)

This file will take you through my design process, in varying amounts of detail.

Otherwise, the files that are possibly of biggest interest are found here:

- [SwarselSystems.org](../SwarselSystems.org)
- [flake.nix](../flake.nix)
- [early-init.el](../programs/emacs/early-init.el)
- [init.el](../programs/emacs/init.el)


## Getting started

### Demo configuration

If you just want to see if this configuration is for you, run this command on any system that has `nix` installed:

``` shell
nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles#rebuild -- -u <YOUR_USERNAME>
```

This will activate the `chaostheatre` configuration on your system, which is a de-facto mirror of my main configuration with secret-based settings removed.
Please keep in mind that this limited installer will make local changes to the cloned repository in order to be able to install it (otherwise the builder would fail at fetching my private secrets repository). As such, this should only be used to evaluate the system - if you want to use it longterm, you will need to create a fork and make some changes.

## Deployment

The deployment process for this configuration is mostly automated, there are only a few steps that are needed to be done manually. You can choose between a remote deployment strategy that is also able to deploy new age keys for sops for you and a local installer that will only install the system without any secret handling.

### Remote deployment (recommended if you have at least one running system)

0) Fork this repo, and write your own host config at `hosts/nixos/<YOUR_CONFIG_NAME>/default.nix` (you can use one of the other configurations as a template. Also see https://github.com/Swarsel/.dotfiles/tree/main/modules for a list of all additional options). At the very least, you should replace the `secrets/` directory with your own secrets and replace the SSH public keys with your own ones (otherwise I will come visit you!🔓❤️). I personally recommend to use the literate configuration and `org-babel-tangle-file` in Emacs, but you can also simply edit the separate `.nix` files.
1) Have a system with `nix` available booted (this does not need to be installed, i.e. you can use a NixOS installer image; a custom minimal installer ISO can be built by running `just iso` in the root of this repo)
2) Make sure that your Yubikey is plugged in or that you have your SSH key available (and configured)
3) Run `bootstrap -n <CONFIGURATION_NAME> -d <TARGET_IP>` on your existing system.
  - Alternatively (if you run this on a system that is not yet running this configuration), you can also run `nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles -- -n <CONFIGURATION_NAME> -d <TARGET_IP>` (this runs the same program as the command above).
4) Follow the installers instructions:
  - you will have to choose a disk encryption password (if you want that feature)
  - you will have to confirm once that the target system has rebooted
  - you will have to enter the root password once during the final system install
5) That should be it! The installer will take care of setting up disks, secrets, and the rest of the hardware configuration! You will still have to sign in manually to some webservices etc.

### Local deployment (recommended for setting up the first system)

1) Boot the latest install ISO from this repository on an UEFI system.
2) Run `swarsel-install -d <TARGET_DISK> -f <FLAKE>`
3) Reboot

Alternatively, to install this from any NixOS live ISO, run `nix run --experimental-features 'nix-command flakes' github:Swarsel/.dotfiles#install -- -d <TARGET_DISK> -f <FLAKE>` at step 2.

## General Nix tips & useful links
- Below is a small list of tips that should be helpful if you are new to the nix ecosystem:

  - Temporarily install any package using `nix shell nixpkgs#<PACKAGE_NAME>` - this can be e.g. useful if you accidentally removed home-manager from your packages on a non-NixOS machine. Alternatively, use [comma](https://github.com/nix-community/comma)
    - More info on `nix [...]` commands: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix
  - When you are trying to setup a new configuration part, GitHub code search can really help you to find a working configuration. Just filter for `.nix` files and the options you are trying to set up.
  - getting packages at a different version than your target (or not packaged at all) can be done in most cases easily with fetchFromGithub (https://ryantm.github.io/nixpkgs/builders/fetchers/)
  - you can easily install old revisions of packages using https://lazamar.co.uk/nix-versions/. You can conveniently spawn a shell with a chosen package available using `vershell <NIXPKGS_REVISION> <PACKAGE>`. Just make sure to pick a revision that has flakes enabled, otherwise you will need the legacy way of spawning the shell (see the link for more info)

- These links are your best friends:
  - The nix documentation: https://nix.dev/
  - The nixpkgs reference manual: https://nixos.org/manual/nixpkgs/unstable/#buildpythonapplication-function
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
  - Also useful is the [NixOS wiki](https://nixos.wiki/wiki/Main_Page), but some pages are outdated, so use with some care
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


## Attributions, Acknowledgements, Inspirations, etc.

These are in random order (also known as 'the order in which I discovered them'). I would like to express my gratitude to:

- All the great people who have contributed code for the nix-community, with special mentions for (this list is unfairly incomplete):
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
- All the people who have inspired me with their configurations (sadly also highly incomplete):
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


If you feel that I forgot to pay you tribute for code that I used in this repository, please shoot me a message and I will fix it :)
