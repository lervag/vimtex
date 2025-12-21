source common.vim

Edit test-macrocode.dtx

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
