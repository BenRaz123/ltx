{
  description = "Latex Flakes";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
        HTML_BOILERPLATE = name: doc: /* html */ ''
          <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <meta http-equiv="X-UA-Compatible" content="ie=edge">
              <title>${name}</title>
            </head>
            <body>
              ${doc}
              <style>
                smaller {
                  font-size:smaller
                } 
                *{
                  font-family:sans-serif
                }
                pre,code {
                  font-family: monospace
                }
                p.tagline {
                  color: gray;
                  font-weight: bold;
                  font-style: italic;
                }
              </style>
            </body>
          </html> 
        '';
        NIX = "nix --extra-experimental-features nix-command --extra-experimental-features flakes";
      in

      {
        apps.buildWebsite = {
          type = "app";
          program = "${lib.getExe (
            pkgs.writeShellApplication {
              name = "build-static-website";
              runtimeInputs = with pkgs; [ nix ];
              text = /* bash */ ''
                pwd
                out=./www
                rm -rf $out
                mkdir -p $out

                cat > "$out/index.html" <<EOF
                  ${HTML_BOILERPLATE "latex templates" /* html */ ''
                    <h1>Latex Templates</h1>
                    <ul>
                    ${lib.concatMapAttrsStringSep "\n" (n: _: /* html */ ''
                      <li><a href="${n}">${n}</a> <smaller><a href="${n}/example.pdf">[PDF]</a></smaller></li>
                    '') self.templates}
                    </ul>
                  ''}
                EOF

                ${lib.concatMapAttrsStringSep "\n" (n: { description, ... }: /* bash */ ''
                  mkdir $out/${n}

                  cat > "$out/${n}/index.html" <<EOF
                    ${HTML_BOILERPLATE "${n} template" /* html */ ''
                      <a href="..">&lt; Back</a>
                      <header>
                        <h1>${n}</h1>
                        <p class="tagline">
                          ${description}
                        </p>
                      </header>
                      <a href="./example.pdf">Example PDF</a>
                      <h2>Setup</h2>
                      <pre>
                        nix flake init -t github:BenRaz123/ltx#${n}
                      </pre>
                      <h2>Nix Flake Show</h2>
                      <pre>
                      <pre>$(nix flake show --all-systems ./${n} | sed 's/\x1b\[[0-9;]*m//g')</pre>
                      <script>
                        const INFO_JSON = $(${NIX} flake show --all-systems --json ./${n});
                      </script>
                    ''}
                  EOF

                  ${NIX} build  ./${n} -o $out/${n}/example.pdf
                '') self.templates}
              '';
            }
          )}";
        };
      }
    ))
    // {
      templates = {
        beamer = {
          path = ./beamer;
          description = "Simple slideshow with beamer Singapore theme";
        };
      };
    };
}
