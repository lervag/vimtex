MYVIM ?= nvim --clean

.PHONY: default perf

default:
	$(MYVIM) -u run-redraws.vim
	head -n 30 out.log

perf: doc1.tex doc2.tex
	eval sudo taskset -c 0 nice -n -11 perf stat -r 4 "nvim --headless --clean -u run-scroll-on-docs.vim" 2>&1 \
	        | sed 's/ \+$$//g' \
	        | grep -v '<not counted>' \
	        | grep -A1 -P 'cycles'
	eval sudo taskset -c 0 nice -n -11 perf stat -r 4 "vim --clean -u run-scroll-on-docs.vim" 2>&1 \
	        | sed 's/ \+$$//g' \
	        | grep -v '<not counted>' \
	        | grep -A1 -P 'cycles'

doc1.tex doc2.tex:
	echo "You need to download these files manually!"
	echo "- https://arxiv.org/abs/1512.07213"
	echo "- https://arxiv.org/abs/1405.0401"
