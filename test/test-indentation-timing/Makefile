MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

ifeq (, $(shell which hyperfine))
  .DEFAULT_GOAL := time
endif

.PHONY: hyperfine time

hyperfine:
	@hyperfine --min-runs 3 '$(MYVIM) -u test.vim'

time:
	@bash -c 'time $(MYVIM) -u test.vim'
