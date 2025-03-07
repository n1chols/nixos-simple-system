{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: let
    mkSystem = {
      hostName ? "nixos",
      userName ? "user",
      systemType ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",
      locale ? "en_US.UTF-8",
      keyboardLayout ? "us",
      cpuVendor ? "intel",
      gpuVendor ? "intel",
      rootDevice ? "/dev/sda",
      bootDevice ? null,
      swapDevice ? null,
      disableNixApps ? true,
      animateStartup ? true,
      autoUpgrade ? true,
      gamingTweaks ? false,
      hiResAudio ? false,
      dualBoot ? false,
      gamepad ? false,
      touchpad ? false,
      bluetooth ? false,
      printing ? false,
      battery ? false,
      extraModules ? []
    }: let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${systemType};
    in
      lib.nixosSystem {
        system = systemType;
        modules = [
          # Mandatory base configuration
          {
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
              networkmanager.enable = true;
              useDHCP = lib.mkDefault true;
              hostName = hostName;
            };
            
            users.users.${userName} = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" ];
            };

            fileSystems."/" = {
              device = rootDevice;
              fsType = "ext4";
            };

            hardware = {
              enableAllFirmware = true;
              enableRedistributableFirmware = true;
              graphics = {
                enable = true;
                enable32Bit = true;
              };
            };
          }

          # CPU Configurations
          (lib.mkIf (cpuVendor == "intel") {
            hardware.cpu.intel.updateMicrocode = true;
          })

          (lib.mkIf (cpuVendor == "amd") {
            hardware.cpu.amd.updateMicrocode = true;
          })

          # GPU Configurations
          (lib.mkIf (gpuVendor == "intel") {
            hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
            services.xserver.videoDrivers = [ "modesetting" ];
          })

          (lib.mkIf (gpuVendor == "amd") {
            hardware.amdgpu.initrd.enable = true;
            services.xserver.videoDrivers = [ "amdgpu" ];
          })

          (lib.mkIf (gpuVendor == "nvidia") {
            hardware.nvidia = {
              open = false;
              nvidiaSettings = true;
              modesetting.enable = true;
              package = pkgs.linuxPackages.nvidiaPackages.stable;
            };
            boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
            services.xserver.videoDrivers = [ "nvidia" ];
          })

          # Boot Configurations
          (lib.mkIf (bootDevice != null) {
            boot.loader.systemd-boot = {
              enable = true;
              configurationLimit = 10;
            };
            boot.loader.efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
            fileSystems."/boot" = {
              device = bootDevice;
              fsType = "vfat";
            };
          })

          (lib.mkIf (bootDevice == null) {
            boot.loader.grub = {
              enable = true;
              devices = [ rootDevice ];
              efiSupport = false;
            };
          })

          (lib.mkIf (swapDevice != null) {
            swapDevices = [{ device = swapDevice; }];
          })

          # Optional Features
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
            services.pulseaudio.enable = false;
            security.rtkit.enable = true;
            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
              extraConfig.pipewire = {
                "context.properties" = {
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

          (lib.mkIf gamepad {
            hardware.xpadneo.enable = true;
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
            services.printing.enable = true;
            services.avahi = {
              enable = true;
              nssmdns4 = true;
              openFirewall = true;
            };
          })

          (lib.mkIf battery {
            services.tlp.enable = true;
            services.upower.enable = true;
          })
        ] ++ extraModules;
      };
  in {
    mkSystem = mkSystem;
  };
}
