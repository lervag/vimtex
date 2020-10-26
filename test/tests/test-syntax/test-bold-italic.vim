source common.vim

let g:tex_conceal = 'b'

silent edit test-bold-italic.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texStyleBoth', 5, 50))
call vimtex#test#assert(vimtex#syntax#in('texStyleBoth', 6, 50))
call vimtex#test#assert(vimtex#syntax#in('texStyleBoth', 7, 50))
call vimtex#test#assert(vimtex#syntax#in('texStyleBoth', 10, 50))
call vimtex#test#assert(vimtex#syntax#in('texCmdStyle', 8, 14))

quit!
