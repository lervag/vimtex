source common.vim

silent edit test-chemformula.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texFootnoteArg', 25, 48))
call assert_true(!vimtex#syntax#in('texCHText', 25, 48))

call vimtex#test#finished()
