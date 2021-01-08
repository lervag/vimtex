MYVIM ?= nvim

.PHONY: default

default:
	hyperfine --min-runs 5 '$(MYVIM) -u minivimrc'

basic:
	time $(MYVIM) -u minivimrc
