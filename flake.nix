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
        }
      ];
    };
  };
}
