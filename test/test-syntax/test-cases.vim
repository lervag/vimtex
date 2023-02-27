source common.vim

EditConcealed test-cases.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
