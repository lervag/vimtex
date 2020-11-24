source common.vim

silent edit test-babel.tex

if empty($INMAKE) | finish | endif

quit!
