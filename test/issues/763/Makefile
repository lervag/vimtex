test: cite ref ref2

cite:
	@nvim -u vimrc_cite

ref: sub.aux test.aux
	@nvim -u vimrc_ref

ref2: sub.aux
	@rm -f test.aux
	@-nvim -u vimrc_ref

sub.aux:
	latexmk sub.tex &>/dev/null

test.aux:
	latexmk test.tex &>/dev/null

