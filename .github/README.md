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

This is a nix flakes based setup that manages multiple hosts, including mixed (NixOS with home-manager as a submodule) as well as standalone home-manager machines, also using some overlays etc. It is all wrapped in literal configuration .org files, because that allows me to have easy access without actually having to remember where the specific configuration files are all located. flake.nix and early-init.el are not tangled at the moment, flake.nix mostly for the reason that I rarely need to update it; early-init.el for the reason that adding it would break the emacs-overlay parsing.

Have fun!

### General Nix tips
Sadly all things nix feel a bit underdocumented. Below is a small list of tips that I thought could be helpful if you are new to the nix ecosystem:

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
1) adapt [flake.nix](../flake.nix):
  - Copy either one of the nixosSystem or homeManagerConfiguration blocks depending on what configuration you are going to be using.
  - Adapt all lines referencing the host- and username to the names chosen for your system.
  - Also adapt the file paths to reference the files where you want your specific configuration to be stored.
  - If using home-manager on the host, consider the settings for `home-manager.useGlobalPkgs` and `home-manager.useUserPackages` - in this repo they are moved to the general NixOS section to reduce code duplication.
2) adapt [Nix.org](../Nix.org)
  - Make a copy of "System Specific Configurations/TEMPLATE".
  - Adapt all references to TEMPLATE to your host- and usernames etc (make sure to also create that directory where it is to be tangled to).
  - Add the settings needed for your specific machine.
  - Make sure Nix.org was actually tangled.
  - **Beware:** This assumes you have access to a way of tangling an .org file (for most people this will mean having a working Emacs). If you do not have that, see below.
3) Add your changes to your fork of the repository.
###### If you have no way of tangling .org files
In that case make a copy of the /.dotfiles/profiles/TEMPLATE folder and adapt each file manually according to the above.
##### Actual system setup
0) Make sure you have an internet connection (ethernet or for Wi-Fi e.g. call `nmtui`)
1) `sudo nano /etc/nixos/configuration.nix`
- add the following packages to `environment.systemPackages`: 
	- `git `
	- `gnupg`
	- `ssh-to-age`
- add
```nix
nix = {
  package = pkgs.nixFlakes;
  extraOptions = ''
    experimental-features = nix-command flakes
  '';
};
```
2) `sudo nixos-rebuild switch`
###### Host SSH key setup for use with sops-nix (only needed if you want to use sops-nix for secrets management)
3) `ssh-keygen -t ed25519 -C "<YOUR_HOSTNAME> sops"`, use e.g. "sops" as name for `<SOPS_KEY>`
4) `cd ~/.dotfiles`
5) `cat ~/<SOPS_KEY>.pub | ssh-to-age >> ~/.dotfiles/.sops.yaml`
6) `nano .sops.yaml` - add last line to keys and make a new &system_<xxx> entry, make sure to remove that last line
7) `cp ~/<SOPS_KEY>.pub ~/.dotfiles/secrets/keys/<YOUR_HOSTNAME>.pub`
8) move `<SOPS_KEY>` to where you want to store your host private key
9) update entry for `sops.age.sshKeyPaths` in Nix.org to the location that you have just moved the private key to (or manually edit `.dotfiles/profiles/<YOUR_HOSTNAME>/home.nix`)
###### Switching to the configuration
10) `cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/profiles/<YOUR_HOSTNAME>`
11) `sudo nixos-rebuild --flake .#<YOUR_HOSTNAME> switch`
  - This build will take a while (mostly because it fully builds Emacs), so do not worry too much :)
  - In case you get a dependency error for some of the `firefox-addons`, just comment out those specific extensions and try to uncomment them again a few days later. Sometimes when these packages are updated, the old .xpi file is deleted by the addon developer and the download link breaks. It is usually updated swiftly. If you do not want to wait, you can also package the addon yourself - there is one example in the files how this is generally done.
