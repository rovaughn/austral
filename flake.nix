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
          ];
        };
      });
  };
}
