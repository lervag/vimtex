source common.vim

let g:tex_nospell = 1
let g:vimtex_syntax_nospell_commands = ['mygls']

silent edit test-nospell.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texVimtexNoSpell', 8, 14))
call vimtex#test#assert(vimtex#syntax#in('texMatcher', 7, 14))
call vimtex#test#assert(vimtex#syntax#in('texBoldItalStyle', 9, 18))
call vimtex#test#assert(vimtex#syntax#in('texItalStyle', 10, 11))

quit!
