{
  outputs = { nixpkgs }: {
    __functor = self: outputs: let
      inherit (outputs) stateVersion systems shells;
      lib = nixpkgs.lib;
    in outputs // {
      nixosConfigurations = lib.mapAttrs
        (hostName: cfg: self.system ({
          inherit hostName stateVersion;
          userName = "user";
        } // cfg))
        systems;

      devShells.x86_64-linux = lib.mapAttrs
        (name: cfg: self.devShell ({
          name = name;
          system = "x86_64-linux";
        } // cfg))
        shells;
    };

    system = {
      stateVersion ? null,
      hostName ? "nixos",
      userName ? "user",
      systemType ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",
      locale ? "en_US.UTF-8",
      keyboardLayout ? "us",
      cpuVendor ? null,
      gpuVendor ? null,
      rootDevice ? null,
      bootDevice ? null,
      swapDevice ? null,
      disableNixApps ? true,
      audio ? false,
      gamepad ? false,
      bluetooth ? false,
      printing ? false,
      touchpad ? false,
      battery ? false,
      packages ? [],
      modules ? []
    }: let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${systemType};
    in lib.nixosSystem {
      system = systemType;
      modules = [
        ({ ... }: {
          # Set NixOS state version
          system.stateVersion = stateVersion;

          # Allow unfree packages
          nixpkgs.config.allowUnfree = true;

          # Add system packages
          environment.systemPackages = packages;

          # Enable flakes
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            warn-dirty = false;
          };

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

          # Specify filesystem root device
          fileSystems."/" = {
            device = rootDevice;
            fsType = "ext4";
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
          # Enable intel media driver
          hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
        })
        (lib.mkIf (gpuVendor == "amd") {
          # Enable amdgpu and kvm-amd driver
          boot.kernelModules = [ "amdgpu" "kvm-amd" ];

          # Enable amdgpu driver for xserver
          services.xserver.videoDrivers = [ "amdgpu" ];
        })
        (lib.mkIf (gpuVendor == "nvidia") {
          # Enable nvidia driver
          hardware.nvidia = {
            open = false;
            nvidiaSettings = true;
            modesetting.enable = true;
            package = pkgs.linuxPackages.nvidiaPackages.stable;
          };
          services.xserver.videoDrivers = [ "nvidia" ];
        })
        (lib.mkIf (bootDevice == null) {
          # Enable GRUB bootloader
          boot.loader.grub = {
            enable = true;
            devices = [ rootDevice ];
            efiSupport = false;
          };
        })
        (lib.mkIf (bootDevice != null) {
          # Enable EFI boot loader
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

          # Specify filesystem boot device
          fileSystems."/boot" = {
            device = bootDevice;
            fsType = "vfat";
          };
        })
        (lib.mkIf (swapDevice != null) {
          # Specify filesystem swap device
          swapDevices = [{ device = swapDevice; }];
        })
        (lib.mkIf disableNixApps {
          # Disable documentation and xterm app
          documentation.nixos.enable = false;
          services.xserver.excludePackages = [ pkgs.xterm ];

          # Remove NixOS default packages
          environment.defaultPackages = [];
        })
        (lib.mkIf audio {
          # Enable RTKit
          security.rtkit.enable = true;

          # Enable PipeWire with sample rate switching
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
        (lib.mkIf gamepad {
          # Enable xpadneo driver
          hardware.xpadneo.enable = true;
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

    # DevShell: creates a development shell for a given system and name
    devShell = {
      system ? "x86_64-linux",
      name,
      packages ? [],
      hook ? ""
    }: let
      pkgs = nixpkgs;
      resolvedPackages = builtins.map (pkg:
        if builtins.isString pkg
        then pkgs.${pkg}
        else pkg
      ) packages;
    in {
      devShells.${system}.${name} = pkgs.mkShell {
        packages = resolvedPackages;
        shellHook = hook;
      };
    };
  };
}
