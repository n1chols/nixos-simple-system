## Usage Example
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    simple-system.url = "github:n1chols/nixos-simple-system";
  };

  outputs = { simple-system, ... }: {
    nixosConfigurations.desktop = simple-system {
      hostName = "desktop";
      userName = "user";

      bootDevice = "/dev/nvme0n1p1";
      rootDevice = "/dev/nvme0n1p2";
      swapDevice = "/dev/nvme0n1p3";

      cpuVendor = "amd";
      gpuVendor = "amd";

      audio = true;
      bluetooth = true;
      printing = true;

      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            firefox
            obsidian
          ];

          services.desktopManager.plasma6.enable = true;
        })
      ];
    };
  };
}

```
