source common.vim

silent edit test-hyperref.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texArgUrl', 6, 25))
call vimtex#test#assert(vimtex#syntax#in('texArgRef', 16, 35))

quit!
