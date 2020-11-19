source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texNewenvParm', 29, 36))

call vimtex#test#assert(vimtex#syntax#in('texVerbRegionInline', 35, 36))

call vimtex#test#assert(vimtex#syntax#in('texAuthorArg', 55, 20))
call vimtex#test#assert(vimtex#syntax#in('texDelim', 55, 39))

quit!
