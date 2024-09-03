# Usage
1. Add the flake to your inputs
2. Add the NixOS module to your NixOS configuration modules
3. Enable it in your NixOS config
```nix
rust = {
  enable = true;
  flavor = "nightly";
};
```
