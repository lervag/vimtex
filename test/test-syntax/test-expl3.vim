source common.vim

silent edit test-expl3.tex

if empty($INMAKE) | finish | endif

call assert_true(!vimtex#syntax#in('texGroupError', 29, 1))

call vimtex#test#finished()
