MYVIM ?= nvim --clean --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)

.PHONY: dummy test $(TESTS)

test: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@


dummy:
	@echo Compiling...
	@echo SillyWalks
	@echo Compiling...Done!
