{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: {
    mkSystem = {
      # System
      hostName ? "nixos",
      userName ? "user",
      systemType ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",
      locale ? "en_US.UTF-8",
      keyLayout ? "us",

      # Hardware
      cpuVendor ? "intel",
      gpuVendor ? "intel",
      rootDevice ? "/dev/sda",
      bootDevice ? "",
      swapDevice ? "",

      # Features
      disableNixApps ? true,
      animateStartup ? true,
      autoUpgrade ? true,
      gamingTweaks ? false,
      hiResAudio ? false,
      dualBoot ? false,
      touchpad ? false,
      bluetooth ? false,
      printing ? false,
      battery ? false,

      # Extra modules
      extraModules ? []
    }: 
    nixpkgs.lib.nixosSystem {
      system = systemType;
      modules = [
        {
          # Nix Config
          system.stateVersion = "24.11";
          nixpkgs.config.allowUnfree = true;
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
            warn-dirty = false;
          };

          # System Config
          time.timeZone = timeZone;
          i18n.defaultLocale = locale;
          console.keyMap = keyLayout;
          networking = {
            hostName = hostName;
            networkmanager.enable = true;
          };
          users.users.${userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
          };

          # Hardware Config
          hardware = {
            enableAllFirmware = true;
            enableRedistributableFirmware = true;
            cpu = nixpkgs.lib.mkMerge [
              (nixpkgs.lib.mkIf (cpuVendor == "intel") {
                intel.updateMicrocode = true;
              })
              (nixpkgs.lib.mkIf (cpuVendor == "amd") {
                amd.updateMicrocode = true;
              })
            ];
            gpu = nixpkgs.lib.mkMerge [
              (nixpkgs.lib.mkIf (gpuVendor == "nvidia") {
                nvidia = {
                  nvidiaSettings = true;
                  modesetting.enable = true;
                  open = false;
                  package = nixpkgs.linuxPackages.nvidiaPackages.stable;
                };
              })
              (nixpkgs.lib.mkIf (gpuVendor == "amd") {
                amdgpu = {
                  enable = true;
                  amdvlk = true;
                  loadInInitrd = true;
                };
              })
            ];
          };
          graphics = {
            enable = true;
            enable32Bit = true;
            extraPackages = nixpkgs.lib.mkIf (gpuVendor == "intel") [
              nixpkgs.packages.intel-media-driver
            ];
          };
          boot = {
            loader = if bootDevice != "" then {
              systemd-boot.enable = true;
              efi.canTouchEfiVariables = true;
            } else {
              grub = {
                enable = true;
                device = rootDevice;
                efiSupport = false;
              };
            };
          };
          fileSystems = {
            "/" = nixpkgs.lib.mkIf (rootDevice != "") {
              device = rootDevice;
              fsType = "ext4";
            };
          } // nixpkgs.lib.optionalAttrs (bootDevice != "") {
            "/boot" = {
              device = bootDevice;
              fsType = "vfat";
            };
          };
          swapDevices = nixpkgs.lib.optional (swapDevice != "") {
            device = swapDevice;
          };
        }
        (nixpkgs.lib.mkIf disableNixApps {
          documentation.nixos.enable = false;
          services.xserver.excludePackages = [ nixpkgs.xterm ];
          environment.defaultPackages = [];
        })
        (nixpkgs.lib.mkIf animateStartup {
          boot.plymouth = {
            enable = true;
            theme = "spinner";
          };
        })
        (nixpkgs.lib.mkIf autoUpgrade {
          system.autoUpgrade = {
            enable = true;
            allowReboot = false;
            dates = "04:00";
          };
        })
        (nixpkgs.lib.mkIf gamingTweaks {
          boot = {
            kernelPackages = nixpkgs.linuxPackages_xanmod;
            kernel.sysctl = {
              "vm.swappiness" = 10;
              "vm.vfs_cache_pressure" = 50;
              "kernel.sched_autogroup_enabled" = 0;
            };
            kernelParams = [
              "mitigations=off"
              "nowatchdog"
            ];
          };
        })
        (nixpkgs.lib.mkIf hiResAudio {
          hardware.pulseaudio.enable = false;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            extraConfig.pipewire = {
              "context.properties" = {
                "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
              };
            };
          };
        })
        (nixpkgs.lib.mkIf dualBoot {
          time.hardwareClockInLocalTime = true;
          boot.loader.grub.useOSProber = true;
        })
        (nixpkgs.lib.mkIf touchpad {
          services.xserver.libinput = {
            enable = true;
            touchpad = {
              tapping = true;
              naturalScrolling = true;
            };
          };
        })
        (nixpkgs.lib.mkIf bluetooth {
          hardware.bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
          services.blueman.enable = true;
        })
        (nixpkgs.lib.mkIf printing {
          services.printing.enable = true;
          services.avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
          };
        })
        (nixpkgs.lib.mkIf battery {
          services.tlp.enable = true;
          services.upower.enable = true;
        })
      ] ++ extraModules;
    };
  };
}
