{ ... }:
{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  programs.texfmt.enable = true;

  settings.formatter.texfmt = {
    includes = [
      "*.tex"
      "*.bib"
      "*.cls"
      "*.sty"
    ];
  };
}
