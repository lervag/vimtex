source common.vim

silent edit test-cases.tex

if empty($INMAKE) | finish | endif

quit!
