source common.vim

EditConcealed test-sagetex.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
