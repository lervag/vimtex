source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texCmdError', 5, 3))
call vimtex#test#assert(vimtex#syntax#in('texCmdSty', 8, 3))

call vimtex#test#assert(vimtex#syntax#in('texRegionVerbInline', 17, 36))

quit!
