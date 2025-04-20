# nixos-simple-system
A rigid flake to output a working system for any personal computer using the simplest set of options possible.

This flake works by wrapping `nixpkgs.lib.nixosSystem`, intending to be a more minimal/vanilla alternative to higher level wrappers like [flake-parts](https://github.com/hercules-ci/flake-parts).

## Options
| Option           | Description                                | Default               |
|------------------|--------------------------------------------|-----------------------|
| `systemType`     | System architecture                        | `x86_64-linux`        |
| `timeZone`       | System timezone                            | `America/Los_Angeles` |
| `locale`         | System locale                              | `en_US.UTF-8`         |
| `keyboardLayout` | Keyboard layout                            | `us`                  |
| `rootDevice`     | Root filesystem device                     | None                  |
| `bootDevice`     | Boot filesystem device (will enable EFI)   | None                  |
| `swapDevice`     | Swap device                                | None                  |
| `cpuVendor`      | CPU vendor (`intel`, `amd`)                | None                  |
| `gpuVendor`      | GPU vendor (`intel`, `amd`, `nvidia`)      | None                  |
| `audio`          | Enable PipeWire audio                      | `false`               |
| `bluetooth`      | Enable Bluetooth                           | `false`               |
| `printing`       | Enable printing w/ discovery               | `false`               |
| `gamepad`        | Enable gamepad driver                      | `false`               |
| `touchpad`       | Enable touchpad                            | `false`               |
| `battery`        | Enable battery management                  | `false`               |
| `virtualization` | Enable virtualization                      | `false`               |
| `modules`        | Additional NixOS modules                   | `[]`                  |

## Usage Example
You can set up a working and featured system with a configuration like the following:
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

      rootDevice = "/dev/nvme0n1p2";
      bootDevice = "/dev/nvme0n1p1";

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
