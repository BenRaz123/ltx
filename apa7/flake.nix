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
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            texliveFull
            gnumake
          ];
        };

        formatter = treefmtEval.config.build.wrapper;

        apps = {
          watch = {
            type = "app";
            program = "${lib.getExe (
              pkgs.writeShellApplication {
                name = "ltxWatch";
                runtimeInputs = with pkgs; [ texliveFull ];
                text = ''
                  rm -rf build
                  mkdir build
                  cp -rs "$(pwd)/src/." build/
                  cd build
                  latexmk -xelatex -pvc  -interaction=nonstopmode\
                    -usepretex='\def\DRAFT{Yes}' main.tex
                '';
              }
            )}";
          };
        };

        packages =
          let
            mkCompile =
              pre:
              pkgs.runCommand "compile-for-draft"
                {
                  buildInputs = with pkgs; [ texliveFull ];
                }
                ''
                  cp -r ${./src}/* .

                  args=(
                    "-xelatex" 
                    "-interaction=nonstopmode"
                  )
                  if [[ "${pre}" != "" ]]; then
                    args+=( "-usepretex=${pre}" )
                  fi

                  args+=(./main.tex)
                    
                  latexmk ''${args[@]}
                  cp main.pdf $out
                '';
          in
          rec {
            default = draft;
            draft = mkCompile "\\def\\DRAFT{Yes}";
            release = mkCompile "";
          };
      }
    );
}
