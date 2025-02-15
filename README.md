## Config
#### System
```python
hostName   # default: nixos
userName   # default: user
systemType # default: x86_64-linux
timeZone   # default: America/Los_Angeles
locale     # default: en_US.UTF-8
keyLayout  # default: us
```

#### Hardware
```python
cpuVendor  # default: intel
gpuVendor  # default: intel
rootDevice # default: /dev/sda
bootDevice # default: null
swapDevice # default: null
```

#### Features
```python
disableNixApps # default: true   Disable unnecessary inlcuded packages
animateStartup # default: true   Enable boot loading animation
autoUpdate     # default: true   Periodically update packages
gamingTweaks   # default: false  Enable gaming-related optimizations
hiResAudio     # default: false  Enable Hi-res audio
dualBoot       # default: false  Support dual booting other OSes
bluetooth      # default: false  Enable bluetooth service
printing       # default: false  Enable printing support
touchpad       # default: false  Enable touchpad support
battery        # default: false  Enable battery management
```
