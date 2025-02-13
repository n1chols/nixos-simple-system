{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: {
    mkSystem = {
      hostName ? "nixos",
      userName ? "user",
      systemType ? "x86_64-linux",
      timeZone ? "America/Los_Angeles",
      hiResAudio ? false,
      optimizeGaming ? false,
      disableNixApps ? false,
      bluetoothService ? false,
      portableDevice ? false,
      dualBoot ? false
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
              "kernel.sched_autogroup_enabled" = 0;
            };
            kernelParams = [
              "mitigations=off"
            ];
          };
          graphics = {
            enable = true;
            enable32Bit = true;
          };
        })
        (nixpkgs.lib.mkIf disableNixApps {
          documentation.nixos.enable = false;
          services.xserver.excludePackages = [ nixpkgs.xterm ];
          environment.defaultPackages = [];
        })
        (nixpkgs.lib.mkIf bluetoothService {
          hardware.bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
          services.blueman.enable = true;
        })
        (nixpkgs.lib.mkIf portableDevice {
          services.tlp.enable = true;
          services.upower.enable = true;
        })
        (nixpkgs.lib.mkIf dualBoot {
          time.hardwareClockInLocalTime = true;
          boot.loader.grub.useOSProber = true;
        })
      ];
    };
  };
}
