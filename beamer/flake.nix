{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (nixpkgs) lib;
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
