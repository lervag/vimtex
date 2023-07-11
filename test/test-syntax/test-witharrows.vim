source common.vim

EditConcealed test-witharrows.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
