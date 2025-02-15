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
        hardware = lib.mkMerge [
          {
            graphics = {
              enable = true;
              enable32Bit = true;
            };
          }
          (lib.mkIf (gpuVendor == "intel") {
            graphics.extraPackages = [ pkgs.intel-media-driver ];
          })
          (lib.mkIf (gpuVendor == "amd") {
            amdgpu = {
              enable = true;
              amdvlk = true;
              loadInInitrd = true;
            };
          })
          (lib.mkIf (gpuVendor == "nvidia") {
            nvidia = {
              open = false;
              nvidiaSettings = true;
              modesetting.enable = true;
              package = pkgs.linuxPackages.nvidiaPackages.stable;
            };
          })
        ];
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
