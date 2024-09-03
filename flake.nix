{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    rust-overlay,
    ...
  }: let
    WASMToolchainFile = ./wasm-toolchain.toml;
    WASMToolchainSettings = {
      extensions = ["rust-src"];
      targets = ["wasm32-unknown-unknown"];
    };
    overlays = rec {
      wasm = final: _: {
        rust-wasm-toolchain =
          (final.rust-bin.fromRustupToolchainFile WASMToolchainFile).override WASMToolchainSettings;
      };
      stable = final: _: {
        rust-toolchain =
          final.rust-bin.stable.latest.default;
      };
      default = stable;
      nightly = final: _: {
        rust-nightly-toolchain =
          final.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
      };
      oxalica = import rust-overlay;
    };

    packageForEachSystem = flake-utils.lib.eachDefaultSystem (system: let
      # packages = let
      pkgs = import nixpkgs {
        inherit system;
        overlays = builtins.attrValues overlays;
      };
    in {
      unwrapped = {
        # default = packages.rust-stable;
        rust-wasm = pkgs.rust-wasm-toolchain;
        rust-stable = pkgs.rust-toolchain;
        rust-nightly = pkgs.rust-nightly-toolchain;
      };
    });
    packages = packageForEachSystem.unwrapped;
  in rec {
    inherit packages overlays;

    nixosModules = {
      default = {
        lib,
        pkgs,
        config,
        ...
      }: {
        config = let
          system = pkgs.system;
          cfgCheck = config: toolchain: config.rust.enable && config.rust.flavor == toolchain;
        in {
          environment.systemPackages = [
            (lib.mkIf (cfgCheck config "wasm") packages.${system}.rust-wasm)
            (lib.mkIf (cfgCheck config "stable") packages.${system}.rust-stable)
            (lib.mkIf (cfgCheck config "nightly") packages.${system}.rust-nightly)
          ];
        };
        options = {
          rust = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install the rust toolchain";
            };
            flavor = lib.mkOption {
              type = lib.types.enum ["wasm" "stable" "nightly"];
              default = "stable";
              description = "Which version of the rust-toolchain to install";
            };
          };
        };
      };
    };
  };
}
