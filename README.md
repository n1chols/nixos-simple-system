## Usage Example
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    simple-flake.url = "github:n1chols/nixos-simple-flake";
  };

  outputs = { simple-flake, ... }: {
    systems = {
      htpc = {
        stateVersion = "24.11";

        bootDevice = "/dev/nvme0n1p1";
        rootDevice = "/dev/nvme0n1p2";
        swapDevice = "/dev/nvme0n1p3";

        cpuVendor = "amd";
        gpuVendor = "amd";

        audio = true;
        bluetooth = true;

        modules = [
          ./modules/steam.nix
          ./modules/kodi.nix
          ./modules/roon-server.nix
        ];
      };
    };
    shells = {
      python = {
        packages = [ python3 ];
        hook = "python --version";
      };
      java = {
        packages = [ jdk maven ];
        hook = "java --version";
      };
    };
  };
}
```
