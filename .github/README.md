###### Disclaimer

You probably do not want to use this setup verbatim. This is made to fit my specific use cases, with some strings hardcoded and some niche settings that are not needed on most hosts. Also, nothing is ever stable here and changes are made on a daily basis.

That being said, there is a lot of general configuration that you *probably* can use without changes; if you only want to use this repository as a starting point for your own configuration, you should be fine. See below for more information. Also, if you see something that can be done more efficiently or better in general, please let me know! :)

# \~SwarselSystems\~

<img src="swarselsystems_preview.png"/>

|               |                      |
|---------------|----------------------|
| **Shell:**    | zsh                  |
| **DM:**       | greetd               |
| **WM:**       | SwayFX               |
| **Bar:**      | Waybar               |
| **Editor:**   | Emacs                |
| **Terminal:** | kitty                |
| **Launcher:** | fuzzel               |
| **Alerts:**   | mako                 |
| **Browser:**  | firefox              |
| **Theme:**    | city-lights          |

The files that are possibly of biggest interest are found here:

- [flake.nix](../flake.nix)
- [Nix.org](../Nix.org)
- [early-init.el](../programs/emacs/early-init.el)
- [Emacs.org](../Emacs.org)

This is a nix flakes based setup that manages multiple hosts, including mixed (NixOS with home-manager as a submodule) as well as standalone home-manager machines, also using some overlays etc. There even is a configuration for an Android build. It is all wrapped in literal configuration .org files, because that allows me to have easy access without actually having to remember where the specific configuration files are all located. early-init.el is not tangled for the reason that adding it would break the emacs-overlay parsing.

Have fun!

### General Nix tips
Sadly all things nix feel a bit underdocumented (even though it mostly is not). Below is a small list of tips that I thought could be helpful if you are new to the nix ecosystem:

- Once you have the experimental feature `nix-command` enabled, you can temporarily install any package using `nix shell nixpkgs#<PACKAGE_NAME>` - this can be e.g. useful if you accidentally removed home-manager from your packages on a non-NixOS machine.
  - The `nix [...]` commands are generally very useful, more info can be found here: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix
- These links are your best friends:
  - https://search.nixos.org/packages
  - https://search.nixos.org/options
  - https://nix-community.github.io/home-manager/options.html / https://mipmip.github.io/home-manager-option-search/
- Also useful is the [NixOS wiki](https://nixos.wiki/wiki/Main_Page), but some pages are outdated, so use with some care
- When you are trying to setup a new configuration part, GitHub code search can really help you to find a working configuration.
- getting packages not maintained in a standard repository can be done in most cases easily with fetchFromGithub (https://ryantm.github.io/nixpkgs/builders/fetchers/)

### Deployment
Below is a rough general guide to setup this system on a new NixOS host. **Again**, this is not recommended as this is a personal configuration. This also might not be the most efficient way to deploy a new Nix system, but it should work in the general case.

For a pure Home-Manager configuration, you need a few different steps. The biggest change is that you then want to call `home-manager --flake .#<your-username>@<your-hostname> switch` as the last step instead of `nixos-rebuild [...]`. A complete general guide for that case cannot really be given since you are most likely setting up the flake on a existing machine that already has a lot of configuration. If you are setting up a new system, I would recommend to use NixOS unless circumstances force you to use something else.

###### To do that:
1) adapt [Nix.org](../.dotfiles/Nix.org)
    1) adapt system specific options:
        - Make a copy of "System Specific Configurations/TEMPLATE".
        - Adapt all references to TEMPLATE to your host- and usernames etc - pay special attention to the header lines in each nix source block, i.e. the "#+begin_src nix [...] :tangle profiles/TEMPLATE/[...]" lines.

        - Add the settings needed for your specific machine.
    2) adapt flake:
        - add a configuration block to "Noweb-Ref blocks/flake.nix/nixosConfigurations" (for example, you can copy one of the other blocks),
            - adapt the paths to the files you chose to tangle to.
            - adjust the "Inputs & Inputs@Outputs" and "let" sections if needed.
        - (Use "[...]/homeConfigurations" instead if adding a home-manager config.)
2) Make sure Nix.org was actually tangled.
- **Beware:** This assumes you have access to a way of tangling an .org file (for most people this will mean having a working Emacs). If you do not have that, see below.
###### If you have no way of tangling .org files
In that case make a copy of the /.dotfiles/profiles/TEMPLATE folder and adapt each file manually according to the above, then edit the /.dotfiles/flake.nix manually.
##### Basic system setup
0) Make sure you have an internet connection (ethernet or for Wi-Fi e.g. call `nmcli`/`nmtui`)
1) `nix --experimental-features 'nix-command flakes' shell nixpkgs#git`
2) `git clone https://github.com/Swarsel/dotfiles.git`
3) `cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/profiles/<YOUR_HOSTNAME>`
4) `git -C ~/.dotfiles add ~/dotfiles/profiles/<YOUR_HOSTNAME>`
5) `sudo nixos-rebuild --flake ~/.dotfiles/#<YOUR_HOSTNAME> boot`
6) Reboot.
  - This build will take a while (mostly because it fully builds Emacs), so do not worry too much :)
  - If you want to use sops-nix for secrets management, you need to provide your own key as well as a key for each host you are going to create. Then you need to adapt `.sops.yaml` to account for these keys and the directory where you are going to store the secrets. You can edit the secrets using `sops` using your key for authentication. You also need to edit the respective sections of the configuration to account for these locations.
  - In case you get a dependency error for some of the `firefox-addons`, just comment out those specific extensions and try to uncomment them again a few days later. Sometimes when these packages are updated, the old .xpi file is deleted by the addon developer and the download link breaks. It is usually updated swiftly. If you do not want to wait, you can also package the addon yourself - there is one example in the files how this is done in general.
