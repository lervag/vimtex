MYVIM ?= nvim --clean --headless
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-latexmk --version
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

$(TESTS):
	$(MAKE) -C $@


#
# Ensure that some goals are run first/last
#
ifndef MAKECMDGOALS
test: sysinfo
$(TESTS): sysinfo

FILTERED := test-indentation-timing
test-indentation-timing: | $(filter-out $(FILTERED), $(TESTS))

FILTERED += test-completion-bibtex-speed
test-completion-bibtex-speed: | $(filter-out $(FILTERED), $(TESTS))

FILTERED += test-completion-bibtex
test-completion-bibtex: | $(filter-out $(FILTERED), $(TESTS))
endif
