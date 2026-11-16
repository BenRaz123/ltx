{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (nixpkgs) lib;
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        tl = (
          pkgs.texlive.withPackages (
            ps: with ps; [
              latexmk

              xetex
              fontspec
              gofonts
              xkeyval # dep
              beamer
              tools # dep
              #xcolor
              #pgf

              fontawesome5
              orcidlink
            ]
          )
        );
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        packages.default = (
          pkgs.runCommand "build-slides"
            {
              buildInputs = [ tl ];
            }
            ''
              mkdir src
              cp -r ${./src}/. ./src/
              latexmk ./src/main.tex \
                -xelatex \
                -interaction=nonstopmode
              cp main.pdf $out
            ''
        );
        apps.watch = {
          type = "app";
          program = "${lib.getExe (
            pkgs.writeShellApplication {
              name = "ltxwatch";
              runtimeInputs = [ tl ];
              text = ''
                pwd
                rm -rf build
                mkdir -p build/src
                cp -rs "$(pwd)/src/." build/src
                cd build
                latexmk -xelatex -pvc  -interaction=nonstopmode\
                  src/main.tex
              '';
            }
          )}";
        };
        devShells.default = pkgs.mkShellNoCC {
          packages = [
            tl
          ];
        };
      }
    );
}
