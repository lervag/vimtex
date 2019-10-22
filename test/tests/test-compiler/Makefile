MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test

test: latexrun
	@PATH=$$PATH:. chronic $(MYVIM) -u test.vim
	@rm -f minimal.*

latexrun:
	@wget \
	  https://raw.githubusercontent.com/aclements/latexrun/master/latexrun \
	  >/dev/null 2>&1
	@chmod u+x latexrun
