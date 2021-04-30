source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texNewenvParm', 36, 36))

call vimtex#test#assert(vimtex#syntax#in('texVerbZoneInline', 42, 36))

call vimtex#test#assert(vimtex#syntax#in('texAuthorArg', 62, 20))
call vimtex#test#assert(vimtex#syntax#in('texDelim', 62, 39))

quit!
