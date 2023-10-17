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
        # TODO (import rust-overlay)
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: (
        let

          # rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          #   targets = [ "wasm32-wasi" ];
          # };
          rustToolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
            # extensions = [ "rust-src" ];
            targets = [
              # "x86_64-unknown-linux-musl"
              "wasm-unknown-unknown"
            ];
          });

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          my-crate = craneLib.buildPackage {
            # https://crane.dev/getting-started.html
            src = craneLib.cleanCargoSource (craneLib.path ./.);

            CARGO_BUILD_TARGET = "wasm-unknown-unknown";
            # CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
            CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            # Add extra inputs here or any other derivation settings
            # doCheck = true;
            # buildInputs = [];
            # nativeBuildInputs = [];
          };
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          checks = {
            inherit my-crate;
          };

          packages.default = my-crate;

          devenv.shells.default = {
            # name = name;

            # https://devenv.sh/reference/options/
            packages = with pkgs; [
              nixpkgs-fmt
              nil
              # (lib.traceVal config.packages.default)
            ];

            # enterShell = ''
            #   hello
            # '';

            # # ? Not sure if needed
            # env = /* nixpkgs.lib.trace "${rust}/lib/rustlib/src/rust/library" */ [
            #   { name = "RUST_SRC_PATH"; value = "${rust}/lib/rustlib/src/rust/library"; }
            # ];
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
