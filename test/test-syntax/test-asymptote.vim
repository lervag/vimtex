source common.vim

set runtimepath^=.

EditConcealed test-asymptote.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
