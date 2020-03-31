source common.vim

silent edit test-wiki.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#util#in_syntax('texZoneWiki', 6, 1))
" call vimtex#test#assert(vimtex#util#in_syntax('markdownHeader', 7, 1))

quit!
