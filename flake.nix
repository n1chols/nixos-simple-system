{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    nixosSystem = {
      # System Configuration
      hostName ? "nixos",
      userName ? "user",
      system ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",
      locale ? "en_US.UTF-8",
      keyboardLayout ? "us",

      # Hardware Configuration
      cpuVendor ? "intel",
      gpuVendor ? "intel",
      rootDevice ? "/dev/sda",
      bootDevice ? "",
      swapDevice ? "",

      # Feature Flags
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

      # Additional Configuration
      extraModules ? []
    }: 
    let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      # Hardware-specific configurations
      cpuConfig = {
        hardware = {
          enableAllFirmware = true;
          enableRedistributableFirmware = true;
          cpu = lib.mkMerge [
            (lib.mkIf (cpuVendor == "intel") {
              intel.updateMicrocode = true;
            })
            (lib.mkIf (cpuVendor == "amd") {
              amd.updateMicrocode = true;
            })
          ];
        };
      };

      gpuConfig = {
        hardware = {
          graphics = {
            enable = true;
            enable32Bit = true;
          } // lib.mkIf (gpuVendor == "intel") {
            extraPackages = [ pkgs.intel-media-driver ];
          };
        #} // lib.mkIf (gpuVendor == "amd") {
         # amdgpu = {
         #   enable = true;
         #   amdvlk = true;
         #   loadInInitrd = true;
         # };
        #} // lib.mkIf (gpuVendor == "nvidia") {
         # nvidia = {
         #   open = false;
         #   nvidiaSettings = true;
         #   modesetting.enable = true;
         #   package = pkgs.linuxPackages.nvidiaPackages.stable;
         # };
        };
      };

      # System configurations
      baseSystemConfig = {
        system.stateVersion = "24.11";
        nixpkgs.config.allowUnfree = true;
        
        nix.settings = {
          experimental-features = [ "nix-command" "flakes" ];
          auto-optimise-store = true;
          warn-dirty = false;
        };

        time.timeZone = timeZone;
        i18n.defaultLocale = locale;
        console.keyMap = keyboardLayout;
        
        networking = {
          hostName = hostName;
          networkmanager.enable = true;
        };

        users.users.${userName} = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" ];
        };
      };

      # Boot and filesystem configurations
      bootConfig = lib.mkMerge [
        {
          fileSystems."/" = {
            device = rootDevice;
            fsType = "ext4";
          };
        }
        (lib.mkIf (bootDevice != "") {
          boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };
          fileSystems."/boot" = {
            device = bootDevice;
            fsType = "vfat";
          };
        })
        (lib.mkIf (bootDevice == "") {
          boot.loader.grub = {
            enable = true;
            device = rootDevice;
            efiSupport = false;
          };
        })
        (lib.mkIf (swapDevice != "") {
          swapDevices = [{ device = swapDevice; }];
        })
      ];

      # Feature configurations
      featureModules = [
        (lib.mkIf disableNixApps {
          documentation.nixos.enable = false;
          services.xserver.excludePackages = [ pkgs.xterm ];
          environment.defaultPackages = [];
        })

        (lib.mkIf animateStartup {
          boot.plymouth = {
            enable = true;
            theme = "spinner";
          };
        })

        (lib.mkIf autoUpgrade {
          system.autoUpgrade = {
            enable = true;
            allowReboot = false;
            dates = "04:00";
          };
        })

        (lib.mkIf gamingTweaks {
          boot = {
            kernelPackages = pkgs.linuxPackages_xanmod;
            kernel.sysctl = {
              "vm.swappiness" = 10;
              "vm.vfs_cache_pressure" = 50;
              "kernel.sched_autogroup_enabled" = 0;
            };
            kernelParams = [ "mitigations=off" "nowatchdog" ];
          };
        })

        (lib.mkIf hiResAudio {
          security.rtkit.enable = true;
          services = {
            pulseaudio.enable = false;
            pipewire = {
              enable = true;
              alsa = {
                enable = true;
                support32Bit = true;
              };
              pulse.enable = true;
              extraConfig.pipewire."context.properties" = {
                "default.clock.allowed-rates" = [
                  44100 48000 88200 96000 176400 192000
                ];
              };
            };
          };
        })

        (lib.mkIf dualBoot {
          time.hardwareClockInLocalTime = true;
          boot.loader.grub.useOSProber = true;
        })

        (lib.mkIf touchpad {
          services.xserver.libinput = {
            enable = true;
            touchpad = {
              tapping = true;
              naturalScrolling = true;
            };
          };
        })

        (lib.mkIf bluetooth {
          hardware.bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
          services.blueman.enable = true;
        })

        (lib.mkIf printing {
          services = {
            printing.enable = true;
            avahi = {
              enable = true;
              nssmdns4 = true;
              openFirewall = true;
            };
          };
        })

        (lib.mkIf battery {
          services = {
            tlp.enable = true;
            upower.enable = true;
          };
        })
      ];

    in lib.nixosSystem {
      inherit system;
      modules = [
        baseSystemConfig
        cpuConfig
        gpuConfig
        bootConfig
      ] ++ featureModules ++ extraModules;
    };
  };
}
