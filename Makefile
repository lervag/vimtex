# VimTeX - LaTeX plugin for Vim
#
# Convenience wrapper for the test suite in test/, so that the tests may be run
# from the repository root. See test/Makefile for the details.
#
#   make                             run the full test suite
#   make test-toc                    run a single test directory
#   make test/test-toc/test-general  run a single test file
#   make MYVIM="vim -T dumb --not-a-term -n"  run with vanilla vim
#

MAKEFLAGS += --no-print-directory

TESTS := $(notdir $(wildcard test/test-*))

.PHONY: test sysinfo $(TESTS)

test:
	@$(MAKE) -C test

sysinfo $(TESTS):
	@$(MAKE) -C test $@

# Allow paths as targets, e.g. `make test/test-toc/test-general`
test/%: FORCE
	@$(MAKE) -C $(dir $@) $(notdir $@)

.PHONY: FORCE
FORCE:
