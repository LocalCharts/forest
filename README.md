# Setup Instructions

1. Install [nix](https://nixos.org/explore). The best way to do this if you don't already have nix installed is via the [Determinate Nix installer](https://github.com/DeterminateSystems/nix-installer). If you are on macOS, you can do this without even going into Terminal.app, with the [Graphical Nix Installer](https://determinate.systems/posts/graphical-nix-installer).
2. Clone this repository with `git clone https://github.com/LocalCharts/forest`, or if you have an SSH key on github, `git clone git@github.com:LocalCharts/forest`.
3. Move into the directory you cloned into with `cd forest`
4. Run `nix develop`. This step might take a while the first time as it installs OCaml and TeXlive.
5. Run `forester-dev`. This will start a server at `http://localhost:8080` which serves the built version of the forest. Note that if you go to `http://localhost:8080` you will get a blank screen; you have to go to `http://localhost:8080/index.xml` to get the main page, or `http://localhost:8080/namespace-XXXX.xml` for looking at other pages.
6. Edit some files in the `trees/` directory! For a reference on forester syntax, see [The Forester markup language](http://www.jonmsterling.com/jms-007N.xml).
