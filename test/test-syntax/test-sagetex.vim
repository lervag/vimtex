source common.vim

silent edit test-sagetex.tex

if empty($INMAKE) | finish | endif


call vimtex#test#finished()
