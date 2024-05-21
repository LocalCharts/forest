{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    systems.url = "github:nix-systems/default";
    forester.url = "sourcehut:~jonsterling/ocaml-forester";
    forest-server.url = "github:kentookura/forest-server";
    bunnycdn-cli.url = "github:olynch/bunnycdn-cli";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    systems,
    forester,
    forest-server,
    bunnycdn-cli
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
        forester = forester-pkg;
        tldist = tlDist;
        new = pkgs.writeScriptBin "new"
        ''
          ${forester-pkg}/bin/forester new --dirs=trees --dest=trees --prefix=$1
        '';
        build = pkgs.writeScriptBin "build"
        ''
          ${forester-pkg}/bin/forester build --dev --root ${default-tree}-0001 trees/
        '';
        serve = pkgs.writeScriptBin "serve"
        ''
          ${pkgs.python3}/bin/python3 -m http.server -d output 8080
        '';
        forester-dev = pkgs.writeScriptBin "forester-dev"
        ''
          ${forest-server.packages.${system}.default}/bin/forest watch $@ -- "build --dev --root ${default-tree}-0001 trees/"
        '';
        forest = pkgs.stdenv.mkDerivation {
          name = "localcharts-forest-xml";
          src = ./.;
          buildInputs = [
            tlDist
            forester-pkg
          ];
          buildPhase = ''
            forester build --root ${default-tree}-0001 trees/
            mv output/ $out/
            cp pdfbuilds.json $out/
          '';
        };
        pdfbuilds = pkgs.stdenv.mkDerivation {
          name = "localcharts-forest-pdfs";
          unpackPhase = "true";
          buildInputs = [
            tlDist
            pkgs.jq
          ];
          buildPhase = ''
            mkdir -p $out/
            mkdir latex/
            while read build
            do
              tree=$(echo "$build" | jq -r .tree)
              style=$(echo "$build" | jq -r .style)
              ${pkgs.saxon-he}/bin/saxon-he "-s:${forest}/$tree.xml" "-xsl:${forest}/$style.xsl" "-o:$tree.tex"
              pdflatex "$tree.tex"
              cp "$tree.pdf" "$out/"
            done < <(cat ${forest}/pdfbuilds.json | jq -c '.[]')
          '';
        };
        default = pkgs.stdenv.mkDerivation {
          name = "localcharts-forest";
          unpackPhase = "true";
          buildPhase = ''
            mkdir -p $out/
            cp -r ${forest}/* $out/
            cp -r ${pdfbuilds}/* $out/
          '';
        };
        buildkite-deploy = pkgs.writeShellApplication {
          name = "buildkite-deploy";

          runtimeInputs = with pkgs; [
            awscli
          ];

          text = ''
            aws s3 sync ${default} s3://forest.next.localcharts.org
          '';
        };
      };

      devShells.shell-minimal = pkgs.mkShell {
        buildInputs = with pkgs; with self.packages.${system}; [
          forester-pkg new build serve
        ];
      };

      devShells.shell-notex = pkgs.mkShell {
        buildInputs = with pkgs; with self.packages.${system}; [
          forester-pkg new build serve forester-dev
        ];
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; with self.packages.${system}; [
          forester-pkg new build serve
          forester-dev
          forest-server.packages.${system}.default
          tlDist
        ];
      };
    });
}
