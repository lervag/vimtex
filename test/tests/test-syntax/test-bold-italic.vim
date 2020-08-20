source common.vim

let g:tex_conceal = ''

silent edit test-bold-italic.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texItalBoldStyle', 5, 55))
call vimtex#test#assert(vimtex#syntax#in('texBoldItalStyle', 6, 55))

quit!
