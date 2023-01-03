BIN := austral
SRC := lib/*.ml lib/*.mli lib/*.mll lib/*.mly lib/dune bin/dune bin/austral.ml lib/BuiltInModules.ml

.PHONY: all
all: $(BIN)

lib/BuiltInModules.ml: lib/builtin/*.aui lib/builtin/*.aum lib/prelude.h lib/prelude.c
	python3 concat_builtins.py

.PHONY: fix
fix: *.sh flake.nix
	nixfmt --check flake.nix || nixfmt flake.nix
	shfmt -i 2 -s -w *.sh
	shellcheck *.sh

$(BIN): $(SRC)
	dune build
	cp _build/default/bin/austral.exe $(BIN)

.PHONY: test
check: $(BIN) *.sh flake.nix
	nixfmt --check flake.nix
	shellcheck *.sh
	dune runtest

.PHONY: install
install: $(BIN)
	mkdir -p $(PREFIX)/bin
	install -m 755 $(BIN) $(PREFIX)/bin/austral

.PHONY: clean
clean:
	rm -rf $(BIN) _build lib/BuiltInModules.ml result .env.nix
