MYVIM ?= nvim --clean --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)
TESTS := $(filter-out test-backend,$(TESTS:.vim=))

.PHONY: test $(TESTS)

test: test-backend $(TESTS) prepare-test-clean

$(TESTS):
	@$(MYVIM) -u $@.vim

test-backend: latexrun
	@PATH=$$PATH:. chronic $(MYVIM) -u $@.vim
	@rm -f minimal.*
	@rm -f pdflatex*.fls
	@rm -f .latexrun.db.lock
	@rm -rf out

test-clean: prepare-test-clean

prepare-test-clean:
	@touch test-clean.log
	@touch test-clean.aux
	@touch test-clean.pdf
	@touch generated-extra_files.out
	@mkdir -p _minted-test-clean
	@touch _minted-test-clean/stuffhere

latexrun:
	@wget \
	  https://raw.githubusercontent.com/aclements/latexrun/master/latexrun \
	  >/dev/null 2>&1
	@chmod u+x latexrun
