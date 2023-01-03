{
  description = "";
  inputs = { nixpkgs.url = "nixpkgs/nixos-22.11"; };
  outputs = { self, nixpkgs }: {
    packages = nixpkgs.lib.genAttrs [ "x86_64-darwin" "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nixfmt
            pkgs.gnumake
            pkgs.python3
            pkgs.ocaml
            pkgs.dune_3
            pkgs.ocamlPackages.ppx_deriving
            pkgs.ocamlPackages.ounit2
            pkgs.ocamlPackages.sexplib
            pkgs.ocamlPackages.ppx_sexp_conv
            pkgs.ocamlPackages.ppx_deriving
            pkgs.ocamlPackages.batteries
            pkgs.ocamlPackages.findlib
          ];
        };
      });
  };
}
