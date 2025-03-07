{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: args @ {
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
  in nixpkgs.lib.nixosSystem {
    system = systemType;
    modules = [
      # Mandatory base configuration
      ({ ... }: {
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
      })

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
        boo
