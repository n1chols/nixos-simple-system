{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: {
    mkSystem = {
      # System
      hostName ? "nixos",
      userName ? "user",
      systemType ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",

      # Hardware
      cpuVendor ? "intel",
      gpuVendor ? "intel",
      rootDevice ? "/dev/sda"
      bootDevice ? "",
      swapDevice ? "",

      # Features
      disableNixApps ? true,
      quietStartup ? true,
      gamingTweaks ? false,
      hiResAudio ? false,
      dualBoot ? false,
      touchpad ? false,
      bluetooth ? false,
      printing ? false,
      battery ? false
    }: 
    nixpkgs.lib.nixosSystem {
      system = systemType;
      modules = [
        {
          system.stateVersion = "24.11";
          nixpkgs.config.allowUnfree = true;
          time.timeZone = timeZone;
          networking = {
            hostName = hostName;
            networkmanager.enable = true;
          };
          users.users.${userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
          };
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
          };
          graphics = {
            enable = true;
            enable32Bit = true;
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
          boot = {
            initrd.kernelModules = [ "amdgpu" ]; # if vendor gpu is amd
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
        }
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
        (nixpkgs.lib.mkIf optimizeGaming {
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
        (nixpkgs.lib.mkIf disableNixApps {
          documentation.nixos.enable = false;
          services.xserver.excludePackages = [ nixpkgs.xterm ];
          environment.defaultPackages = [];
        })
        (nixpkgs.lib.mkIf quietStartup {
          boot.plymouth = {
            enable = true;
            theme = "spinner";
          };
        })
        (nixpkgs.lib.mkIf dualBoot {
          time.hardwareClockInLocalTime = true;
          boot.loader.grub.useOSProber = true;
        })
        (nixpkgs.lib.mkIf battery {
          services.tlp.enable = true;
          services.upower.enable = true;
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
            nssmdns = true;
            openFirewall = true;
          };
        })
      ];
    };
  };
}
