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
        mkWeb = import ./website.nix { inherit pkgs lib self; };
      in
      {
        apps.buildWebsite = {
          program = "${lib.getExe mkWeb}";
          type = "app";
        };
      }
    ))
    // {
      templates = {
        beamer = {
          path = ./beamer;
          description = "Simple slideshow with beamer Singapore theme";
        };
        apaStu = {
          path = ./apaStu;
          description = "APA Student submission template with bibliography, optional author ORCID and TeX-Gyre fonts (Cursor, Hermes, and Heros)";
        };
      };
    };
}
