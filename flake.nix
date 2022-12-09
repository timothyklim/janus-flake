{
  description = "Janus flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";

    src = {
      url = "github:meetecho/janus-gateway/v1.1.1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, src }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      janus = import ./build.nix { inherit pkgs src; };
      janus-app = flake-utils.lib.mkApp { drv = janus; };
      derivation = { inherit janus; };
    in
    rec {
      packages.${system} = derivation // { default = janus; };
      legacyPackages.${system} = pkgs.extend overlays.default;
      apps.${system} = {
        default = janus-app;
        janus = janus-app;
      };
      devShells.${system}.default = pkgs.callPackage ./shell.nix { inherit janus; };
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
    };
}
