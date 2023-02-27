source common.vim

EditConcealed test-babel.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
