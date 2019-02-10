.PHONY: test1 test2 testall

# testall: test1 test2

test1: | vimtex-old; nvim -u vimrc

test2: | vimtex-old; OLD=1 nvim -u vimrc

vimtex-old:
	git clone ~/.vim/bundle/vimtex vimtex-old
	(cd vimtex-old; git co 327873e49a891a5e16cc5e5c624eb7eb4ebd407d)

