# LocalCharts' Forest

This is a place for writing in the spirit of LocalCharts with high-quality mathematical typesetting. To do this, we use forester to build the source of this website, and then embed comments from the LocalCharts discourse instance.

See [here](https://forest.localcharts.org/lc-0002.xml) for a very quick tour of Forest (and its LocalCharts incarnation).

## Setup Instructions

1. Install [nix](https://nixos.org/explore). The best way to do this if you don't already have nix installed is via the [Determinate Nix installer](https://github.com/DeterminateSystems/nix-installer). If you are on macOS, you can do this without even going into Terminal.app, with the [Graphical Nix Installer](https://determinate.systems/posts/graphical-nix-installer).
2. Clone this repository with `git clone https://github.com/LocalCharts/forest`, or if you have an SSH key on github, `git clone git@github.com:LocalCharts/forest`.
3. Move into the directory you cloned into with `cd forest`

Here you have two choices:
1. The **way God intended** (standard but longer, involves downloading and installing 2GB+ of stuff): 

   This step might take a while the first time as it installs OCaml, TeXlive, and the automatically refreshing preview server.
   1. Run `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop`.
   2. Run `forester-dev`. This will start a server at `http://localhost:8080` which serves the built version of the forest. Note that if you go to `http://localhost:8080` you will get a blank screen; you have to go to `http://localhost:8080/index.xml` to get the main page, or `http://localhost:8080/namespace-XXXX.xml` for looking at other pages.
2. The **shortcut** (less standard but quicker, recommended if you don't use Nix otherwise):

   In this case you must have a recent TeXlive installation on your computer.
   1. Run `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop '.#shell-minimal'`, which only contains forester and the `new` and `build` wrapper commands.
   2. Run `build` to build the site into the `output/` directory, and then run `serve` to start up a server to preview the output; you can then go to `http://localhost:8080/index.xml` as in the previous instructions.

Now you can go and edit some files in the `trees/` directory!
For a general reference on forester syntax, see [The Forester markup language](http://www.jonmsterling.com/jms-007N.xml).

## Contributing

You can send PRs to either [github](https://github.com/LocalCharts/forest) or [codeberg](https://codeberg.org/LocalCharts/forest); they are bidirectionally synced through the magic of distributed version control. The difference is that codeberg doesn't send non-public information associated with your account to Microsoft.
