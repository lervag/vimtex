source common.vim

let &rtp = '.,' . &rtp
let g:vimtex_fold_enabled = 1

silent edit test-listings.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texFileArg', 7, 28))
call vimtex#test#assert(vimtex#syntax#in('texVerbRegionInline', 9, 14))

call vimtex#test#assert(vimtex#syntax#in('texLstRegion', 12, 1))
call vimtex#test#assert(vimtex#syntax#in('texLstRegionC', 20, 1))
call vimtex#test#assert(vimtex#syntax#in('texLstRegionPython', 27, 1))
call vimtex#test#assert(vimtex#syntax#in('texLstRegionRust', 33, 1))

call vimtex#test#assert(vimtex#syntax#in('texLstsetGroup', 38, 10))

quit!
