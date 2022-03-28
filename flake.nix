{
  description = "Janus flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";

    src = {
      url = "github:meetecho/janus-gateway/v1.0.0";
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
      packages.${system} = derivation;
      defaultPackage.${system} = janus;
      legacyPackages.${system} = pkgs.extend overlay;
      apps.janus.${system} = janus-app;
      defaultApp.${system} = janus-app;
      devShell.${system} = pkgs.callPackage ./shell.nix {
        inherit janus;
      };
      nixosModule = {
        imports = [
          ./configuration.nix
        ];
        nixpkgs.overlays = [
          overlay
        ];
        services.janus = {
          package = pkgs.lib.mkDefault janus;
        };
      };
      overlay = final: prev: derivation;
    };
}
