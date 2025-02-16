{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    nixosSystem = {
      # System Configuration
      hostName ? "nixos",
      userName ? "user",
      systemType ? "x86_64-linux", 
      timeZone ? "America/Los_Angeles",
      locale ? "en_US.UTF-8",
      keyboardLayout ? "us",

      # Hardware Configuration
      cpuVendor ? "intel",
      gpuVendor ? "intel",
      rootDevice ? "/dev/sda",
      bootDevice ? null,
      swapDevice ? null,

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
      pkgs = nixpkgs.legacyPackages.${systemType};
    in lib.nixosSystem {
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
            isNormalUser = lib.mkDefault true;
            extraGroups = [ "wheel" "networkmanager" ];
          };

          fileSystems."/" = {
            device = rootDevice;
            fsType = "ext4";
          };

          hardware = {
            enableAllFirmware = lib.mkDefault true;
            enableRedistributableFirmware = lib.mkDefault true;
            graphics = {
              enable = lib.mkDefault true;
              enable32Bit = lib.mkDefault true;
            };
          };
        }

        # CPU Configurations
        (lib.mkIf (cpuVendor == "intel") {
          hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
        })

        (lib.mkIf (cpuVendor == "amd") {
          hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
        })

        # GPU Configurations
        (lib.mkIf (gpuVendor == "intel") {
          hardware.opengl.extraPackages = [ pkgs.intel-media-driver ];
          services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];
        })

        (lib.mkIf (gpuVendor == "amd") {
          hardware.amdgpu.enable = lib.mkDefault true;
          hardware.amdgpu.amdvlk = lib.mkDefault true;
          hardware.amdgpu.loadInInitrd = lib.mkDefault true;
          boot.initrd.kernelModules = [ "amdgpu" ];
          services.xserver.videoDrivers = lib.mkDefault [ "amdgpu" ];
        })

        (lib.mkIf (gpuVendor == "nvidia") {
          hardware.nvidia.open = lib.mkDefault false;
          hardware.nvidia.nvidiaSettings = lib.mkDefault true;
          hardware.nvidia.modesetting.enable = lib.mkDefault true;
          hardware.nvidia.package = lib.mkDefault pkgs.linuxPackages.nvidiaPackages.stable;
          boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
          services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
        })

        # Boot Configurations
        (lib.mkIf (bootDevice != null) {
          boot.loader.systemd-boot.enable = lib.mkDefault true;
          boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
          boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
          boot.loader.efi.efiSysMountPoint = lib.mkDefault "/boot";
          fileSystems."/boot" = {
            device = bootDevice;
            fsType = "vfat";
          };
        })

        (lib.mkIf (bootDevice == null) {
          boot.loader.grub.enable = lib.mkDefault true;
          boot.loader.grub.devices = [ rootDevice ];
          boot.loader.grub.efiSupport = lib.mkDefault false;
        })

        (lib.mkIf (swapDevice != null) {
          swapDevices = [{ device = swapDevice; }];
        })

        # Optional Features
        (lib.mkIf disableNixApps {
          documentation.nixos.enable = lib.mkDefault false;
          services.xserver.excludePackages = [ pkgs.xterm ];
          environment.defaultPackages = [];
        })

        (lib.mkIf animateStartup {
          boot.plymouth.enable = lib.mkDefault true;
          boot.plymouth.theme = lib.mkDefault "spinner";
        })

        (lib.mkIf autoUpgrade {
          system.autoUpgrade.enable = lib.mkDefault true;
          system.autoUpgrade.allowReboot = lib.mkDefault false;
          system.autoUpgrade.dates = lib.mkDefault "04:00";
        })

        (lib.mkIf gamingTweaks {
          boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod;
          boot.kernel.sysctl = {
            "vm.swappiness" = lib.mkDefault 10;
            "vm.vfs_cache_pressure" = lib.mkDefault 50;
            "kernel.sched_autogroup_enabled" = lib.mkDefault 0;
          };
          boot.kernelParams = [ "mitigations=off" "nowatchdog" ];
        })

        (lib.mkIf hiResAudio {
          services.pulseaudio.enable = lib.mkDefault false;
          security.rtkit.enable = lib.mkDefault true;
          services.pipewire.enable = lib.mkDefault true;
          services.pipewire.alsa.enable = lib.mkDefault true;
          services.pipewire.alsa.support32Bit = lib.mkDefault true;
          services.pipewire.pulse.enable = lib.mkDefault true;
          services.pipewire.extraConfig.pipewire."context.properties"."default.clock.allowed-rates" = [ 
            44100 48000 88200 96000 176400 192000 
          ];
        })

        (lib.mkIf dualBoot {
          time.hardwareClockInLocalTime = lib.mkDefault true;
          boot.loader.grub.useOSProber = lib.mkDefault true;
        })

        (lib.mkIf touchpad {
          services.xserver.libinput.enable = lib.mkDefault true;
          services.xserver.libinput.touchpad.tapping = lib.mkDefault true;
          services.xserver.libinput.touchpad.naturalScrolling = lib.mkDefault true;
        })

        (lib.mkIf bluetooth {
          hardware.bluetooth.enable = lib.mkDefault true;
          hardware.bluetooth.powerOnBoot = lib.mkDefault true;
          services.blueman.enable = lib.mkDefault true;
        })

        (lib.mkIf printing {
          services.printing.enable = lib.mkDefault true;
          services.avahi.enable = lib.mkDefault true;
          services.avahi.nssmdns4 = lib.mkDefault true;
          services.avahi.openFirewall = lib.mkDefault true;
        })

        (lib.mkIf battery {
          services.tlp.enable = lib.mkDefault true;
          services.upower.enable = lib.mkDefault true;
        })
      ] ++ extraModules;
    };
  };
}
