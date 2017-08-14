test: ref cite

cite:
	@nvim -u vimrc_cite

ref: sub.aux test.aux
	@nvim -u vimrc_ref

sub.aux:
	latexmk sub.tex

test.aux:
	latexmk test.tex

