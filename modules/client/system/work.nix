{ config, ... }:
let
  fmods = config.flake.modules;
in
{
  flake-file.inputs.vbc-nix = {
    inputs = {
      nixpkgs.follows = "nixpkgs-stable26_05";
      nixpkgs-2411.follows = "nixpkgs-stable24_11";
      systems.follows = "systems";
    };
    url = "git+ssh://git@github.com/vbc-it/vbc-nix.git?ref=main";
  };

  flake.modules = {
    homeManager.work = {
      imports = [
        fmods.homeManager.work-mail
        fmods.homeManager.work-dev
        fmods.homeManager.work-desktop
      ];
      config.swarselsystems.enabledHomeModules = [ "optional-work" ];
    };
    nixos.work =
      {
        self,
        inputs,
        config,
        lib,
        pkgs,
        withHomeManager,
        ...
      }:
      let
        inherit (config.swarselsystems) homeDir mainUser;
        iwd = config.networking.networkmanager.wifi.backend == "iwd";
        owner = mainUser;
        sopsFile = self + /secrets/work/secrets.yaml;
      in
      {
        options.swarselsystems = {
          fqdn = lib.mkOption {
            default = "";
            type = lib.types.str;
          };
          hostName = lib.mkOption {
            default = config.node.name;
            type = lib.types.str;
          };
        };
        config = {

          sops =
            let
              secretNames = [
                "vcuser"
                "vcpw"
                "govcuser"
                "govcpw"
                "govcurl"
                "govcdc"
                "govcds"
                "govchost"
                "govcnetwork"
                "govcpool"
                "baseuser"
                "basepw"
              ];
            in
            {
              secrets = builtins.listToAttrs (
                map (name: {
                  inherit name;
                  value = { inherit owner sopsFile; };
                }) secretNames
              );
              templates = {
                "network-manager-work.env".content = ''
                  BASEUSER=${config.sops.placeholder.baseuser}
                  BASEPASS=${config.sops.placeholder.basepw}
                '';
              };
            };
          services = {
            openssh = {
              enable = true;
              extraConfig = "";
            };
            spice-vdagentd.enable = true;
            syncthing = {
              settings = {
                folders = {
                  "Documents" = {
                    devices = [ "moonside@oracle" ];
                    id = "hgr3d-pfu3w";
                    path = "${homeDir}/Documents";
                  };
                };
                "moonside@oracle" = {
                  id = "VPCDZB6-MGVGQZD-Q6DIZW3-IZJRJTO-TCC3QUQ-2BNTL7P-AKE7FBO-N55UNQE";
                };
                "winters" = {
                  id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
                };
              };
            };
            # udev.extraRules = ''
            #   # lock screen when yubikey removed
            #             ACTION=="remove", ENV{PRODUCT}=="3/1050/407/110", RUN+="${pkgs.systemd}/bin/systemctl suspend"
            # '';

          };
          programs = {

            _1password.enable = true;
            _1password-gui = {
              enable = true;
              package = pkgs._1password-gui;
              polkitPolicyOwners = [ "${mainUser}" ];
            };
            browserpass.enable = true;
          };
          boot.initrd = {
            luks = {
              fido2Support = false;
              # disable "support" since we use systemd-cryptenroll
              # make sure yubikeys are enrolled using
              # sudo systemd-cryptenroll --fido2-device=auto --fido2-with-user-verification=no --fido2-with-user-presence=true --fido2-with-client-pin=no /dev/nvme0n1p2
              yubikeySupport = false;
            };
            systemd.enable = lib.mkForce true; # make sure we are using initrd systemd even when not using Impermanence
          };
          environment = {
            etc."1password/custom_allowed_browsers" = {
              mode = "0755";
              text = ''
                glide
              '';
            };
            systemPackages = with pkgs; [
              remmina
              python39
              qemu
              packer
              gnumake
              libisoburn
              govc
              terraform
              opentofu
              terragrunt
              graphviz
              azure-cli

              # vm
              virt-manager
              virt-viewer
              virtiofsd
              spice
              spice-gtk
              spice-protocol
              virtio-win
              win-spice

              powershell
              gh
            ];
          };
          networking = {
            inherit (config.swarselsystems) fqdn hostName;

            networkmanager = {
              ensureProfiles = {
                environmentFiles = [
                  "${config.sops.templates."network-manager-work.env".path}"
                ];
                profiles = {
                  VBC = {
                    "802-1x" = {
                      eap = if (!iwd) then "ttls;" else "peap;";
                      identity = "$BASEUSER";
                      password = "$BASEPASS";
                      phase2-auth = "mschapv2";
                    };
                    connection = {
                      autoconnect-priority = "500";
                      id = "VBC";
                      secondaries = "48d09de4-0521-47d7-9bd5-43f97e23ff82"; # vpn uuid
                      type = "wifi";
                      uuid = "3988f10e-6451-381f-9330-a12e66f45051";
                    };
                    ipv4 = {
                      method = "auto";
                    };
                    ipv6 = {
                      # addr-gen-mode = "default";
                      addr-gen-mode = "stable-privacy";
                      method = "auto";
                    };
                    proxy = { };
                    wifi = {
                      band = "a";
                      cloned-mac-address = "permanent";
                      mac-address = "E8:65:38:52:63:FF";
                      mac-address-randomization = "1";
                      mode = "infrastructure";
                      ssid = "VBC";
                    };
                    wifi-security = {
                      # auth-alg = "open";
                      key-mgmt = "wpa-eap";
                    };
                  };
                };
              };
              wifi.scanRandMacAddress = false;
            };

            nftables = {
              chains.postrouting.libvirt-masq = {
                after = [ "dnat" ];
                rules = [
                  "iifname \"virbr*\" masquerade"
                ];
              };
              firewall = {
                rules = {
                  virbr-dns-dhcp = {
                    allowedTCPPorts = [ 53 ];
                    allowedUDPPorts = [
                      53
                      67
                      547
                    ];
                    from = [ "virbr" ];
                    to = [ "local" ];
                  };
                  virbr-forward = {
                    from = [ "virbr" ];
                    to = [ "untrusted" ];
                    verdict = "accept";
                  };
                  virbr-forward-return = {
                    extraLines = [
                      "ct state { established, related } accept"
                    ];
                    from = [ "untrusted" ];
                    to = [ "virbr" ];
                  };
                };
                zones = {
                  virbr = {
                    interfaces = [ "virbr*" ];
                  };
                };
              };
            };

            search = [
              "vbc.ac.at"
              "clip.vbc.ac.at"
              "imp.univie.ac.at"
            ];
          };
          nixpkgs.overlays = [
            (
              final: prev:
              lib.genAttrs [
                "aap-mcp-server"
                "aci-mcp-server"
                "artifactory-mcp"
                "crowdsec-mcp"
                "defender-mcp"
                "foreman-mcp-server"
                "infoblox-mcp-server"
                "intune-mcp"
                "ise-mcp"
                "jamf-mcp"
                "jenkins-mcp-server"
                "jfrog-mcp-server"
                "koppla"
                "netbox-mcp-server"
                "ontap-mcp"
                "openshift-mcp-server"
                "openstack-mcp-server"
                "palo-alto-mcp"
                "rustdesk-vbc"
                "snipeit-mcp"
                "vcenter-mcp"
              ] (name: ((inputs.vbc-nix.overlays.default or (_: _: { })) final prev).${name})
            )
          ];
          repo.secretFiles.work = ../../../secrets/work/pii.nix.enc;
          virtualisation = {
            docker.enable = lib.mkIf (!config.virtualisation.podman.dockerCompat) true;
            libvirtd = {
              enable = true;
              qemu = {
                package = pkgs.qemu_kvm;
                runAsRoot = true;
                swtpm.enable = true;
                vhostUserPackages = with pkgs; [ virtiofsd ];
              };
            };
            spiceUSBRedirection.enable = true;
          };
          systemd.services = {
            virtnetworkd.path = with pkgs; [
              dnsmasq
              iproute2
              nftables
            ];
            virtqemud.path = with pkgs; [
              qemu_kvm
              libvirt
            ];
            virtstoraged.path = with pkgs; [
              qemu_kvm
              libvirt
            ];
          };
          # cgroups v1 is required for centos7 dockers
          # specialisation = {
          #   cgroup_v1.configuration = {
          #     boot.kernelParams = [
          #       "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
          #       "systemd.unified_cgroup_hierarchy=0"
          #     ];
          #   };
          # };
        }
        // lib.optionalAttrs withHomeManager {

          home-manager.users."${config.swarselsystems.mainUser}" = {
            imports = [
              fmods.homeManager.work
            ];
          };
        };

      };
  };
}
