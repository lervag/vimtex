set nocompatible
set runtimepath^=../..
set runtimepath+=../../after
filetype plugin indent on
syntax enable

function! SynGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun

function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

nnoremap zS :call SynStack()<CR>
color desert

nnoremap q :qall!<cr>

let g:vimtex_syntax_conceal_disable = 1
let g:vimtex_syntax_match_unicode = 0
silent edit main.tex


set nolazyredraw
let LINES = line('$')
syntime on
for s:x in range(2*LINES/winheight(0))
  norm! 
  redraw!
endfor

let s:lines = split(execute('syntime report'), "\n")
call writefile(s:lines, "out.log")

quitall
