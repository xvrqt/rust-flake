{
  inputs = {
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
    };
  };

  outputs = {rust-overlay, ...}: let
    WASMToolchainFile = ./wasm-toolchain.toml;
    WASMToolchainSettings = {
      extensions = ["rust-src"];
      targets = ["wasm-unknown-unknown"];
    };
    rustOverlay = import rust-overlay;
    rustToolchain = {
      wasm = final: _: {
        rust-wasm-toolchain =
          (final.rust-bin.fromRustupToolchainFile WASMToolchainFile).override WASMToolchainSettings;
      };
      stable = final: _: {
        rust-toolchain =
          final.rust-bin.stable.latest.default;
      };
      nightly = final: _: {
        rust-nightly-toolchain =
          final.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
      };
    };
  in {
    overlays = rec {
      all = [rustOverlay] ++ wasm ++ stable ++ nightly;
      wasm = [rustOverlay rustToolchain.wasm];
      stable = [rustOverlay rustToolchain.stable];
      nightly = [rustOverlay rustToolchain.nightly];
      default = stable;
    };
  };
}
