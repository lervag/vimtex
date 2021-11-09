source common.vim

silent edit test-chemformula.tex

if empty($INMAKE) | finish | endif

quit!
