MYVIM ?= nvim --clean

.PHONY: default basic

default:
	hyperfine --min-runs 5 '$(MYVIM) -u minivimrc'

basic:
	time $(MYVIM) -u minivimrc
