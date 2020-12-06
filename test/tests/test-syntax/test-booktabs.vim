source common.vim

silent edit test-booktabs.tex

if empty($INMAKE) | finish | endif


quit!
