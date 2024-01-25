{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    wrangler-nixpkgs.url = "github:NixOS/nixpkgs/8dfad603247387df1df4826b8bea58efc5d012d8";
    systems.url = "github:nix-systems/default";
    forester.url = "sourcehut:~jonsterling/ocaml-forester";
    forest-server.url = "github:kentookura/forest-server";
  };

  outputs = {
    self,
    nixpkgs,
    wrangler-nixpkgs,
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
      wrangler-pkgs = import wrangler-nixpkgs {
        inherit system;
      };
      forester-pkg = forester.packages.${system}.default;
      default-tree = "lc";
      tlDist = pkgs.texliveFull;
    in {
      packages = flake-utils.lib.flattenTree rec {
        new = pkgs.writeScriptBin "new"
        ''
          ${forester-pkg}/bin/forester new --dir trees --prefix=$1
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
        buildkite-deploy = pkgs.writeShellApplication {
          name = "buildkite-deploy";

          runtimeInputs = with pkgs; [ forester-pkg wrangler-pkgs.nodePackages.wrangler curl gnused tlDist ];

          text = ''
            forester build --root ${default-tree}-0001 trees/
            cp _redirects output/
            wrangler pages deploy --branch "$BUILDKITE_BRANCH" --project-name localcharts-forest output/ | tee wrangler-log
            DEPLOY_URL=$(sed -n 's/.*Take a peek over at \(.*\)/\1/p' < wrangler-log)
            curl -L \
              -X POST \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "https://api.github.com/repos/LocalCharts/forest/commits/$BUILDKITE_COMMIT/comments" \
                -d "{\"body\":\"Deployed at $DEPLOY_URL\"}"
          '';
        };
      };

      devShells.shell-minimal = pkgs.mkShell {
        buildInputs = with pkgs; with self.packages.${system}; [
          forester-pkg new build serve
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
