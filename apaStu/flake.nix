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
        inherit (pkgs) lib;

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        fonts = [
          pkgs.gyre-fonts
        ];

        fontconfig = pkgs.makeFontsConf {
          fontDirectories = fonts;
        };

        texlive = pkgs.texlive.withPackages (
          ps: with ps; [
            latexmk
            xetex
            biber

            # Document packages
            apa7
            orcidlink
            fontspec
            newtx
            fontaxes
            carlisle
            xstring
            xkeyval
            amsmath
            oberdiek
            xpatch

            # TeX Gyre fonts and APA dependencies
            draftwatermark
            tools
            etoolbox
            geometry
            scalerel
            pgf
            hyperref
            booktabs
            threeparttable
            caption
            fancyhdr
            endfloat
            biblatex
            l3packages
            biblatex-apa
          ]
        );

        mkRun =
          pretex:
          pkgs.runCommand "build-doc"
            {
              FONTCONFIG_FILE = fontconfig;
              nativeBuildInputs = [ texlive ];
            }
            ''
              mkdir -p src
              cp -r ${./src}/. src/

              args=(
                -xelatex
                -interaction=nonstopmode
              )

              if [[ -n "${pretex}" ]]; then
                args+=( "-usepretex=${pretex}" )
              fi

              args+=(src/main.tex)

              latexmk "''${args[@]}"

              cp main.pdf "$out"
            '';
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        packages = rec {
          release = mkRun "";
          draft = mkRun ''\def\DRAFT{Yes}'';
          default = draft;
        };

        apps.watch = {
          type = "app";
          program = "${lib.getExe (
            pkgs.writeShellApplication {
              name = "ltxwatch";

              runtimeInputs = [
                texlive
              ];

              runtimeEnv.FONTCONFIG_FILE = fontconfig;

              text = ''
                rm -rf build
                mkdir -p build/src
                cp -rs "$(pwd)/src/." build/src/

                cd build

                latexmk \
                  -xelatex \
                  -pvc \
                  -interaction=nonstopmode \
                  -usepretex='\def\DRAFT{Yes}' \
                  src/main.tex
              '';
            }
          )}";
        };

        devShells.default = pkgs.mkShellNoCC {
          packages = [
            texlive
          ];

          FONTCONFIG_FILE = fontconfig;
        };
      }
    );
}
