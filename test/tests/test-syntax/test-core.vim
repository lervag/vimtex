source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texCmdError', 5, 3))
call vimtex#test#assert(vimtex#syntax#in('texCmdSty', 8, 3))

call vimtex#test#assert(vimtex#syntax#in('texParmNewenv', 20, 36))

call vimtex#test#assert(vimtex#syntax#in('texRegionVerbInline', 26, 36))

call vimtex#test#assert(vimtex#syntax#in('texArgAuthor', 46, 20))
call vimtex#test#assert(vimtex#syntax#in('texDelim', 46, 39))

quit!
