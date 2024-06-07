{
  description = "Janus flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    src = {
      url = "github:meetecho/janus-gateway/v1.2.2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, src }:
    with flake-utils.lib; eachSystem [ system.x86_64-linux system.aarch64-linux system.aarch64-darwin ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        janus = import ./build.nix { inherit pkgs src; };
        janus-app = flake-utils.lib.mkApp { drv = janus; };
        derivation = { inherit janus; };
      in
      rec {
        packages = derivation // { default = janus; };
        legacyPackages = pkgs.extend overlays.default;
        apps = {
          default = janus-app;
          janus = janus-app;
        };
        devShell = pkgs.callPackage ./shell.nix { inherit janus; };
        nixosModules.default = {
          imports = [
            ./configuration.nix
          ];
          nixpkgs.overlays = [
            overlays.default
          ];
          services.janus = {
            package = pkgs.lib.mkDefault janus;
          };
        };
        overlays.default = final: prev: derivation;
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      });
}
