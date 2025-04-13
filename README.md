## Usage Example
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-simplex.url = "github:n1chols/flake-simplex";
  };

  outputs = { flake-simplex, ... }: {
    systems = {
      htpc = {
        stateVersion = "24.11";

        cpuVendor = "amd";
        gpuVendor = "amd";

        bootDevice = "/dev/nvme0n1p1";
        rootDevice = "/dev/nvme0n1p2";
        swapDevice = "/dev/nvme0n1p3";

        audio = true;
        gamepad = true;

        modules = [
          ./modules/steam.nix
          ./modules/kodi.nix
          ./modules/roon-server.nix
        ];
      };
    };

    shells = {
      python = {
        packages = ps: with ps; [ python3 python.requests python.pandas python.black python.ipython ];
        hook = "echo 'Python version: $(python --version)'";
      };
      nodejs = {
        packages = [ nodejs yarn ];
        hook = "echo 'Node.js version: $(node --version)'";
      };
      java = {
        packages = [ jdk maven ];
        hook = "echo 'Java version: $(java --version)'";
      };
    };
  };
}
```
