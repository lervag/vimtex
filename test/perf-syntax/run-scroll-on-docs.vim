set nocompatible
set runtimepath^=../..
set runtimepath+=../../after
filetype plugin indent on
syntax enable

set nolazyredraw
set columns=130

function! Scroll()
  let l:steps = range(2*line('$')/winheight(0))
  for l:_ in l:steps
    execute "normal! \<c-d>"
    redraw!
  endfor
  for l:_ in l:steps
    execute "normal! \<c-u>"
    redraw!
  endfor
endfunction

let g:vimtex_syntax_match_unicode = 0
let g:vimtex_syntax_conceal_disable = 1
"let g:vimtex_syntax_conceal_disable = 0
"set conceallevel=2
silent edit doc1.tex
call Scroll()

silent edit doc2.tex
call Scroll()

quitall!
