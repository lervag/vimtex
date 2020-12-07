source common.vim

let &rtp = '.,' . &rtp
let g:vimtex_fold_enabled = 1

silent edit test-listings.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texFileArg', 7, 28))
call vimtex#test#assert(vimtex#syntax#in('texVerbZoneInline', 9, 14))

call vimtex#test#assert(vimtex#syntax#in('texLstZone', 12, 1))
call vimtex#test#assert(vimtex#syntax#in('texLstZoneC', 20, 1))
call vimtex#test#assert(vimtex#syntax#in('texLstZonePython', 27, 1))
call vimtex#test#assert(vimtex#syntax#in('texLstZoneRust', 33, 1))

call vimtex#test#assert(vimtex#syntax#in('texLstsetGroup', 38, 10))

quit!
