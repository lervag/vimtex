source common.vim

silent edit test-pythontex.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('pythonString', 11, 13))
call assert_true(vimtex#syntax#in('pythonRawString', 16, 13))

call vimtex#test#finished()
