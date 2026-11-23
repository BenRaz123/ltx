{
  pkgs,
  lib,
  self,
  ...
}:
let
  REPO = "https://github.com/benraz123/ltx";
  REPO_ROOT = "${REPO}/blob/main";
  LATEX = ''<span class="latex">L<sup>a</sup>T<sub>e</sub>X</span>'';
  TEX = ''<span class="tex">T<sub>e</sub>X</span>'';

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
          .tex sub, .latex sub, .latex sup {
            text-transform: uppercase;
          }

          .tex sub, .latex sub {
            vertical-align: -0.5ex;
            margin-left: -0.1667em;
            margin-right: -0.125em;
          }

          .tex, .latex, .tex sub, .latex sub {
            font-size: 1em;
          }

          .latex sup {
            font-size: 0.85em;
            vertical-align: 0.15em;
            margin-left: -0.36em;
            margin-right: -0.15em;
          }

          :root {
            --bg: white;
            --fg: black;
            --dim: gray;
            --link: blue;
          }
          @media (prefers-color-scheme: dark) {
            :root {
              --bg: #111;
              --fg: white;
              --dim: #999;
              --link: #abf;
            }
          }
          *{
            color: var(--fg);
          }
          html {
            background-color: var(--bg);
          }
          a {
            color: var(--link);
          }
          a.btn {
            font-size: smaller;
            font-weight: normal;
            color: var(--fg);
            text-decoration: none;
          }

          a.btn::before {
            content: "[";
            color: var(--dim);
          }

          a.btn::after {
            content: "]";
            color: var(--dim);
          }

          smaller {
            font-size:smaller
          } 
          *{
            font-family:sans-serif
          }
          pre,code {
            font-family: monospace
          }
          p.tagline, p.tagline * {
            color: var(--dim);
            font-weight: bold;
            font-style: italic;
          }

          ul.templates {
            font-size: bigger;
            list-style-type: "> ";
          }

        </style>
      </body>
    </html> 
  '';
  NIX = "nix --extra-experimental-features nix-command --extra-experimental-features flakes";
in
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
        <h1>${LATEX} Templates <a class=btn href="${REPO}">source</a></h1>
        <p class="tagline">
          A set of nix flake templates to make typesetting documents with ${LATEX} easier and more conventient.
        </p>
        <ul class=templates>
        ${lib.concatMapAttrsStringSep "\n" (n: _: /* html */ ''
          <li>template <strong>${n}</strong> <a class=btn href="${n}">link</a></li>
          <!--<a class=btn href="${n}">page</a> <a class=btn href="${REPO_ROOT}/${n}">source</a> <a class=btn href="{n}/example.pdf">example</a>-->
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
            <h1>${n} <a class=btn href="${REPO_ROOT}/${n}">source</a> <a class=btn href="./example.pdf">example</a></h1>
            <p class="tagline">
              ${builtins.replaceStrings [ "TeX" "LaTeX" ] [ TEX LATEX ] description}
            </p>
          </header>
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
