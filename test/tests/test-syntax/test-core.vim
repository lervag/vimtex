source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texCmdError', 5, 3))
call vimtex#test#assert(vimtex#syntax#in('texCmdSty', 8, 3))

call vimtex#test#assert(vimtex#syntax#in('texNewenvParm', 22, 36))

call vimtex#test#assert(vimtex#syntax#in('texVerbRegionInline', 28, 36))

call vimtex#test#assert(vimtex#syntax#in('texAuthorArg', 48, 20))
call vimtex#test#assert(vimtex#syntax#in('texDelim', 48, 39))

quit!
