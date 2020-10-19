source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texErrorStatement', 5, 3))
call vimtex#test#assert(vimtex#syntax#in('texStatementSty', 8, 3))

quit!
