set nocompatible
set runtimepath^=../..
set runtimepath+=../../after
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:vimtex_syntax_conceal_disable = 1
let g:vimtex_syntax_match_unicode = 0
silent edit main.tex

syntime on
for s:x in range(400)
  redraw!
endfor
let s:lines = split(execute('syntime report'), "\n")
call writefile(s:lines, "out.log")

quitall
