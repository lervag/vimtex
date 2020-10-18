source common.vim

silent edit test-wiki.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texRegionWiki', 6, 1))
" call vimtex#test#assert(vimtex#syntax#in('markdownHeader', 7, 1))

quit!
