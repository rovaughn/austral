BIN := austral
SRC := lib/*.ml lib/*.mli lib/*.mll lib/*.mly lib/dune bin/dune bin/austral.ml lib/BuiltInModules.ml

.PHONY: all
all: $(BIN)

lib/BuiltInModules.ml: lib/builtin/*.aui lib/builtin/*.aum lib/prelude.h lib/prelude.c
	python3 concat_builtins.py

.PHONY: fix
fix: *.sh
	shfmt -i 2 -s -w $^
	shellcheck $^

$(BIN): $(SRC)
	dune build
	cp _build/default/bin/austral.exe $(BIN)

.PHONY: test
test: $(BIN)
	dune runtest

.PHONY: install
install: $(BIN)
	install -m 755 austral /usr/local/bin/austral

.PHONY: uninstall
uninstall:
	sudo rm /usr/local/bin/austral

.PHONY: clean
clean:
	rm -rf $(BIN) _build lib/BuiltInModules.ml
