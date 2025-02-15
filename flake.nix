{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
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
            #graphics = nixpkgs.lib.mkMerge [{
            #  enable = true;
            #  enable32Bit = true;
            #} (nixpkgs.lib.mkIf (gpuVendor == "intel") {
            #  extraPackages = [ nixpkgs.legacyPackages.${systemType}.intel-media-driver ];
            #})];
            amdgpu = nixpkgs.lib.mkIf (gpuVendor == "amd") {
              enable = true;
              amdvlk = true;
              loadInInitrd = true;
            };
            nvidia = nixpkgs.lib.mkIf (gpuVendor == "nvidia") {
              open = false;
              nvidiaSettings = true;
              modesetting.enable = true;
              package = nixpkgs.legacyPackages.${systemType}.linuxPackages.nvidiaPackages.stable;
            };
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
            "/" = {
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
      ] ++ extraModules;
    };
  };
}
