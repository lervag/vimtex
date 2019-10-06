MYVIM ?= nvim --headless

MAKE := 1
export MAKE

ifeq (, $(shell which hyperfine))
  .DEFAULT_GOAL := time
endif

hyperfine:
	@hyperfine --min-runs 3 '$(MYVIM) -u test.vim'

time:
	@bash -c 'time $(MYVIM) -u test.vim'

.PHONY: hyperfine time
