source common.vim

EditConcealed test-quantikz.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
