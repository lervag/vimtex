source common.vim

let g:tex_nospell = 1
let g:vimtex_syntax_nospell_commands = ['mygls']

silent edit test-nospell.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texArg', 7, 14))
call assert_true(vimtex#syntax#in('texNoSpellArg', 8, 14))

call vimtex#test#finished()
