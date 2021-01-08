source common.vim

silent edit test-pythontex.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('pythonString', 11, 13))
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 16, 13))

quit!
