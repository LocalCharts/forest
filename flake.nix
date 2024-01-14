{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    systems.url = "github:nix-systems/default";
    forester.url = "github:olynch/ocaml-forester";
    forester.inputs.nixpkgs.follows = "nixpkgs";
    forest-server.url = "github:kentookura/forest-server";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    systems,
    forester,
    forest-server
  }:
    flake-utils.lib.eachSystem (import systems)
    (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      forester-pkg = forester.packages.${system}.default;
      default-tree = "lc";
      tlDist = pkgs.texliveFull;
    in {
      packages = flake-utils.lib.flattenTree rec {
        new = pkgs.writeScriptBin "new"
        ''
          ${forester-pkg}/bin/forester new --dir trees --prefix=${default-tree}
        '';
        forester-dev = pkgs.writeScriptBin "forester-dev"
        ''
          ${forest-server.packages.${system}.default}/bin/forest watch -- "build --dev --root ${default-tree}-0001 trees/"
        '';
        default = pkgs.stdenv.mkDerivation {
          name = "localcharts-forest";
          src = ./.;
          buildInputs = [tlDist];
          buildPhase = ''
            ${forester-pkg}/bin/forester build --root ${default-tree}-0001 trees/
            mv output/ $out/
            mv _redirects $out
          '';
        };
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; with self.packages.${system}; [
          forester-pkg new forester-dev
          forest-server.packages.${system}.default
          tlDist
        ];
      };
    });
}
