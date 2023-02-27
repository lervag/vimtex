source common.vim

EditConcealed test-booktabs.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
