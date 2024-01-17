{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    wrangler-nixpkgs.url = "github:NixOS/nixpkgs/8dfad603247387df1df4826b8bea58efc5d012d8";
    systems.url = "github:nix-systems/default";
    forester.url = "github:olynch/ocaml-forester";
    forester.inputs.nixpkgs.follows = "nixpkgs";
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
        buildkite-deploy = pkgs.writeScriptBin "buildkite-deploy"
        ''
          ${wrangler-pkgs.nodePackages.wrangler}/bin/wrangler pages deploy --branch $BUILDKITE_BRANCH --project-name localcharts-forest result/ | tee wrangler-log
          DEPLOY_URL=$(cat wrangler-log | ${pkgs.gnused}/bin/sed -n 's/.*Take a peek over at \(.*\)/\1/p')
          ${pkgs.curl}/bin/curl -L \
            -X POST \
              -H "Accept: application/vnd.github+json" \
              -H "Authorization: Bearer $GITHUB_TOKEN" \
              -H "X-GitHub-Api-Version: 2022-11-28" \
              https://api.github.com/repos/LocalCharts/forest/deployments \
              -d "{\"ref\":\"$BUILDKITE_COMMIT\",\"payload\":\"{}\",\"description\":\"Deployed at $DEPLOY_URL\"}"
        '';
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
