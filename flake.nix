{
  description = "";
  inputs = { nixpkgs.url = "nixpkgs/nixos-22.11"; };
  outputs = { self, nixpkgs }: {
    packages = nixpkgs.lib.genAttrs [ "x86_64-darwin" "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.stdenv.mkDerivation {
          pname = "austral";
          version = "0.00";
          makeFlags = ["PREFIX=$(out)"];
          buildInputs = [
            pkgs.dune_3
            pkgs.ocaml
            pkgs.ocamlPackages.batteries
            pkgs.ocamlPackages.findlib
            pkgs.ocamlPackages.ounit2
            pkgs.ocamlPackages.menhir
            pkgs.ocamlPackages.ppx_deriving
            pkgs.ocamlPackages.ppx_deriving
            pkgs.ocamlPackages.ppx_sexp_conv
            pkgs.ocamlPackages.sexplib
            pkgs.python3
          ];
          src = pkgs.lib.cleanSource ./.;
        };
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.dune_3
            pkgs.gnumake
            pkgs.nixfmt
            pkgs.ocaml
            pkgs.ocamlPackages.batteries
            pkgs.ocamlPackages.findlib
            pkgs.ocamlPackages.ounit2
            pkgs.ocamlPackages.ppx_deriving
            pkgs.ocamlPackages.ppx_deriving
            pkgs.ocamlPackages.ppx_sexp_conv
            pkgs.ocamlPackages.sexplib
            pkgs.python3
            pkgs.shellcheck
            pkgs.shfmt
          ];
        };
      });
  };
}
