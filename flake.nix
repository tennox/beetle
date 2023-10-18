{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    rust-overlay.url = "github:oxalica/rust-overlay"; # TODO: replace with fenix?
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      # needed for devenv's languages.rust
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, rust-overlay, crane, devenv, ... }: (
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: (
        let

          # rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          #   targets = [ "wasm32-wasi" ];
          # };
          pkgsWithRust = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (import rust-overlay)
            ];
          };
          rustToolchain = pkgsWithRust.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
            # extensions = [ "rust-src" ];
            # targets = [
            #   "x86_64-unknown-linux-musl"
            #   # "wasm-unknown-unknown"
            # ];
          });

          # craneLib = crane.lib.${system};
          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          iroh-one = craneLib.buildPackage rec {
            # https://crane.dev/getting-started.html
            #src = craneLib.cleanCargoSource (craneLib.path ./.);
            # When filtering sources, we want to allow assets other than .rs files
            src = pkgs.lib.cleanSourceWith {
              src = ./.; # The original, unfiltered source
              filter =
                let
                  hasAnyWantedSuffix = path: pkgs.lib.any (suffix: pkgs.lib.hasSuffix suffix path)
                    [ ".proto" ".css" ".html" ];
                in
                path: type:
                  (hasAnyWantedSuffix path) ||
                  # (pkgs.lib.hasInfix "/assets/" path) ||
                  # Default filter from crane (allow .rs files)
                  (craneLib.filterCargoSources path type)
              ;
            };

            pname = "iroh-one";
            cargoExtraArgs = "-p iroh-one --features=http-uds-gateway";
            # cargoVendorDir = null;
            cargoVendorDir = craneLib.vendorCargoDeps { cargoLock = ./Cargo.lock; };

            # CARGO_BUILD_TARGET = "wasm-unknown-unknown";
            # CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
            CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";
            # CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            # Add extra inputs here or any other derivation settings
            doCheck = false;
            buildInputs = with pkgs; [ protobuf clang libclang gcc ];
            LIBCLANG_PATH = "${pkgs.llvmPackages_11.libclang.lib}/lib";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
            #nativeBuildInputs = [];
          };
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          checks = {
            inherit iroh-one;
          };

          packages.default = iroh-one;

          devenv.shells.default = {
            # https://devenv.sh/reference/options/
            packages = with pkgs; [
              nixpkgs-fmt
              nil
            ];
          } // (import ./devenv.nix { inherit pkgs; });
        }
      );
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    }
  );
}
