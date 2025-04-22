{
  outputs = { self, nixpkgs }: {
    __functor = self: {
      systemType ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",
      locale ? "en_US.UTF-8",
      keyboardLayout ? "us",
      hostName ? "nixos",
      userName ? "user",
      rootDevice ? null,
      bootDevice ? null,
      swapDevice ? null,
      cpuVendor ? null,
      gpuVendor ? null,
      audio ? false,
      bluetooth ? false,
      printing ? false,
      gamepad ? false,
      touchpad ? false,
      battery ? false,
      virtualization ? false,
      modules ? []
    }: let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${systemType};
    in lib.nixosSystem {
      system = systemType;
      modules = [
        ({ ... }: {
          # Enable flakes
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          # Allow unfree packages
          nixpkgs.config.allowUnfree = true;

          # Remove default packages
          environment.defaultPackages = [];
          services.xserver.excludePackages = [ pkgs.xterm ];

          # Set timezone, locale, and keyboard
          time.timeZone = timeZone;
          i18n.defaultLocale = locale;
          console.keyMap = keyboardLayout;

          # Enable NetworkManager
          networking = {
            networkmanager.enable = true;
            useDHCP = lib.mkDefault true;
            hostName = hostName;
          };

          # Create user
          users.users.${userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
          };

          # Enable firmware and graphics
          hardware = {
            enableAllFirmware = true;
            enableRedistributableFirmware = true;
            graphics = {
              enable = true;
              enable32Bit = true;
            };
          };

          # Specify filesystem root device
          fileSystems."/" = {
            device = rootDevice;
            fsType = "ext4";
          };
        })
        (lib.mkIf (bootDevice == null) {
          # Enable syslinux boot loader
          boot.loader.syslinux.enable = true;
        })
        (lib.mkIf (bootDevice != null) {
          # Specify filesystem boot device
          fileSystems."/boot" = {
            device = bootDevice;
            fsType = "vfat";
          };

          # Enable EFI and systemd boot loader
          boot.loader = {
            systemd-boot = {
              enable = true;
              configurationLimit = 10;
            };
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
          };
        })
        (lib.mkIf (swapDevice != null) {
          # Specify filesystem swap device
          swapDevices = [{ device = swapDevice; }];
        })
        (lib.mkIf (cpuVendor == "intel") {
          # Enable updating cpu microcode
          hardware.cpu.intel.updateMicrocode = true;
        })
        (lib.mkIf (cpuVendor == "amd") {
          # Enable updating cpu microcode
          hardware.cpu.amd.updateMicrocode = true;
        })
        (lib.mkIf (gpuVendor == "intel") {
          # Enable kvm-intel driver
          boot.kernelModules = [] ++ lib.optionals virtualization [ "kvm-intel" ];

          # Enable intel media driver
          hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

          # Enable intel driver for xserver
          services.xserver.videoDrivers = [ "intel" ];
        })
        (lib.mkIf (gpuVendor == "amd") {
          # Enable amdgpu and kvm-amd driver
          boot.kernelModules = [ "amdgpu" ] ++ lib.optionals virtualization [ "kvm-amd" ];

          # Enable amdgpu driver for xserver
          services.xserver.videoDrivers = [ "amdgpu" ];
        })
        (lib.mkIf (gpuVendor == "nvidia") {
          # Enable vfio-pci driver
          boot.kernelModules = [] ++ lib.optionals virtualization [ "vfio-pci" ];

          # Enable nvidia driver
          hardware.nvidia = {
            open = false;
            nvidiaSettings = true;
            modesetting.enable = true;
            package = pkgs.linuxPackages.nvidiaPackages.stable;
          };

          # Enable nvidia driver for xserver
          services.xserver.videoDrivers = [ "nvidia" ];
        })
        (lib.mkIf audio {
          # Enable RTKit
          security.rtkit.enable = true;

          # Enable PipeWire
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };
        })
        (lib.mkIf bluetooth {
          # Enable bluetooth driver
          hardware.bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
        })
        (lib.mkIf printing {
          # Enable printing service
          services.printing.enable = true;

          # Enable printer autodiscovery
          services.avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
          };
        })
        (lib.mkIf gamepad {
          # Enable xpadneo driver
          hardware.xpadneo.enable = true;
        })
        (lib.mkIf touchpad {
          # Enable touchpad input
          services.xserver.libinput = {
            enable = true;
            touchpad = {
              tapping = true;
              naturalScrolling = true;
            };
          };
        })
        (lib.mkIf battery {
          # Enable tlp with defaults
          services.tlp.enable = true;

          # Enable power management
          services.upower.enable = true;
        })
      ] ++ modules;
    };
  };
}
