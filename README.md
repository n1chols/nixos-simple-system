# nixos-simple-system
A rigid flake to output a working system for any personal computer using the simplest set of options possible.

## Options
Note that the only required option is `rootDevice` to enable a working filesystem.
| Option           | Description                                | Default               | Required |
|------------------|--------------------------------------------|-----------------------|----------|
| `systemType`     | System architecture                        | `x86_64-linux`        | No       |
| `hostName`       | System hostname                            | `nixos`               | No       |
| `userName`       | Primary user                               | `user`                | No       |
| `timeZone`       | System timezone                            | `America/Los_Angeles` | No       |
| `locale`         | System locale                              | `en_US.UTF-8`         | No       |
| `keyboardLayout` | Keyboard layout                            | `us`                  | No       |
| `rootDevice`     | Root filesystem device                     | None                  | Yes      |
| `bootDevice`     | Boot filesystem device (will enable EFI)   | None                  | No       |
| `swapDevice`     | Swap device                                | None                  | No       |
| `cpuVendor`      | CPU vendor (`intel`, `amd`)                | None                  | No       |
| `gpuVendor`      | GPU vendor (`intel`, `amd`, `nvidia`)      | None                  | No       |
| `audio`          | Enable PipeWire audio                      | `false`               | No       |
| `gamepad`        | Enable gamepad driver                      | `false`               | No       |
| `bluetooth`      | Enable Bluetooth                           | `false`               | No       |
| `printing`       | Enable printing w/ discovery               | `false`               | No       |
| `touchpad`       | Enable touchpad                            | `false`               | No       |
| `battery`        | Enable battery management                  | `false`               | No       |
| `modules`        | Additional NixOS modules                   | `[]`                  | No       |

## Usage Example
You can set up a working and featured system with just the following:
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

      cpuVendor = "amd";
      gpuVendor = "amd";

      audio = true;
      bluetooth = true;
      printing = true;

      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            firefox
          ];

          services.desktopManager.plasma6.enable = true;
        })
      ];
    };
  };
}
```
