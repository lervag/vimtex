source common.vim

Edit test-robust-externalize.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
