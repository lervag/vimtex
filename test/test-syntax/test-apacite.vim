source common.vim

Edit test-apacite.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
